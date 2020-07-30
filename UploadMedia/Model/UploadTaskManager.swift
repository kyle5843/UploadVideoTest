//
//  UploadTaskManager.swift
//  UploadMedia
//
//  Created by Kyle on 2020/7/5.
//  Copyright © 2020. All rights reserved.
//

import UIKit
import FirebaseStorage
import Photos
import RxSwift
import RxCocoa
import Reachability

enum UploadState:String {
    case Ready = "Ready to upload"
    case ThunmbNail = "Upload thunmbNail"
    case Compress = "Compress video"
    case Uploading = "Uploading video"
    case Failed = "Failed"
    case Finished = "Finished"
}

class UploadTask :Equatable {
    static func == (lhs: UploadTask, rhs: UploadTask) -> Bool {
        return lhs.info.asset == rhs.info.asset
    }
    
    private var info:MediaInfo
    private var uploadTask:StorageUploadTask?
    private var uploadQueue:OperationQueue
    private var semaphore:DispatchSemaphore
    private var disposeBag = DisposeBag()
    
    init(info:MediaInfo,_ queue:OperationQueue,_ semaphore:DispatchSemaphore) {
        self.info = info
        self.uploadQueue = queue
        self.semaphore = semaphore
    }
    
    func upload(completion:@escaping (UploadTask?) -> Void) {
        self.uploadQueue.addOperation {
            _ = Observable<Error?>.create { [weak self] observer in
                self?.uploadThumbNail { error in
                    observer.onNext(error)
                    observer.onCompleted()
                }
                self?.semaphore.wait()
                return Disposables.create()
            }.flatMap({ _ -> Observable<(URL?, Error?)> in
                return Observable<(URL?, Error?)>.create {  [weak self]  observer in
                    self?.compressVideo(completion: { compressed, error  in
                        observer.onNext((compressed, error))
                        observer.onCompleted()
                    })
                    return Disposables.create()
                }
            }).flatMap({ elements -> Observable<Error?> in
                let (compressed, error) = elements
                return Observable<Error?>.create { [weak self]  observer in
                    if let url = compressed, error == nil {
                        self?.uploadVideo(url: url, completion: { error in
                            observer.onNext(error)
                            observer.onCompleted()
                        })
                    } else {
                        observer.onNext(error)
                        observer.onCompleted()
                    }
                    // 確保上傳順序, upload video 發出後才解鎖
                    self?.semaphore.signal()
                    return Disposables.create()
                }
            }).subscribe(onNext: { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.info.state = .Failed
                    let message = error.localizedDescription
                    SystemAlert.alert(title: "Error", message: message, vc: nil)
                } else {
                    self.info.state = .Finished
                }
                completion(self)
            }).disposed(by: self.disposeBag)
        }
    }
    
    private func uploadThumbNail(completion:@escaping (Error?) -> Void) {
        // reset progress
        self.info.uploadProgress = -1
        self.info.state = .ThunmbNail
        self.uploadTask = UploadAPIHelper.shared.uploadThumbnail(self.info.thunmbNail!, completion: { error in
            completion(error)
        })
        self.uploadTask?.observe(.progress, handler: { [weak self] (storageTaskSnapshot) in
            guard let progress = storageTaskSnapshot.progress else { return }
            let p = progress.fractionCompleted * 100
            self?.info.uploadProgress = p
            NSLog("image upload:\(p)")
        })
    }
    
    private func compressVideo(completion:@escaping (URL?, Error?) -> Void) {
        // reset progress
        self.info.uploadProgress = -1
        self.info.state = .Compress
        CompressHelper.shared.compressed(self.info.asset,  AVAssetExportPresetLowQuality) { (url, error) in
            completion(url, error)
        }
    }
    
    private func uploadVideo(url:URL, completion:@escaping (Error?) -> Void) {
        // reset progress
        self.info.uploadProgress = -1
        self.info.state = .Uploading
        self.uploadTask = UploadAPIHelper.shared.uploadCompressedVideo(url, completion: { (error) in
            completion(error)
        })
        self.uploadTask?.observe(.progress, handler: { [weak self] (storageTaskSnapshot) in
            guard let progress = storageTaskSnapshot.progress else { return }
            let p = progress.fractionCompleted * 100
            self?.info.uploadProgress = p
            NSLog("video upload:\(p)")
        })
    }
    
    func taskFinished() -> Bool {
        return self.info.state == .Finished
    }
    
    func cancel(){
        self.semaphore.signal()
        self.uploadTask?.cancel()
        CompressHelper.shared.cancelExport()
        if !self.taskFinished() {
            self.info.state = .Failed
        }
    }
}

class UploadTaskManager: NSObject {
    
    static let shared = UploadTaskManager()
    private var tasks = Array<UploadTask>()
    private lazy var uploadQueue:OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    private let semaphore = DispatchSemaphore(value: 0)
    private let reachability = try! Reachability()
    private var reachable = false {
        didSet {
            if !reachable {
                self.cancelTask()
            }
        }
    }
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector:#selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        self.checkNetwork()
    }
    
    private func checkNetwork() {
        reachability.whenReachable = { reachability in
            self.reachable = true
            NSLog("reachable")
        }
        reachability.whenUnreachable = { _ in
            self.reachable = false
            NSLog("Not reachable")
        }

        do {
            try reachability.startNotifier()
        } catch {
            NSLog("Unable to start notifier")
        }
    }
    
    func addUploadTask(_ infoArray:Array<MediaInfo>) {
        let newTasks = infoArray.map({ info -> UploadTask in
            return UploadTask.init(info: info, self.uploadQueue, self.semaphore)
        })
        self.tasks.append(contentsOf: newTasks)
        self.startUpload(newTasks)
    }
    
    func startUpload(_ tasks:Array<UploadTask>) {
        if !self.reachable {
            SystemAlert.alert(title: "Error", message: "No network", vc: nil)
            return
        }
        for task in tasks {
            task.upload() { [weak self] uploadTask in
                guard let task = uploadTask else { return }
                // remove task after finish
                if task.taskFinished() {
                    if let index = self?.tasks.firstIndex(of: task) {
                        self?.tasks.remove(at: index)
                    }
                }
            }
        }
    }
    
    func cancelTask(){
        for task in tasks {
            task.cancel()
        }
    }
    
    @objc func applicationDidEnterBackground(){
        self.cancelTask()
    }
}
