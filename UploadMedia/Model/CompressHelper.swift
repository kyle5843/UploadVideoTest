//
//  CompressHelper.swift
//  UploadMedia
//
//  Created by Kyle on 2020/7/5.
//  Copyright © 2020. All rights reserved.
//

import UIKit
import Photos
import RxSwift
import RxRelay

enum CompressError:Error {
    case Failed
    case Cancel
}

class CompressHelper: NSObject {
    
    static let shared = CompressHelper()
    var progress = BehaviorRelay<Double>(value: 0)
    private var exportSession:AVAssetExportSession?
    private let semaphore = DispatchSemaphore(value: 0)
    private lazy var compressQueue:OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    func compressed(_ phAsset:PHAsset, _ quality:String, completion:@escaping (URL?, Error?) -> Void){
        
        PHImageManager.default().requestAVAsset(forVideo: phAsset, options: PHVideoRequestOptions(), resultHandler: { (asset, audioMix, info) -> Void in
            if let asset = asset as? AVURLAsset {
                let fileWithExt = asset.url.absoluteString.components(separatedBy: "/").last
                let fileName = fileWithExt!.components(separatedBy: ".").first
                let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + fileName! + ".MP4")

                // also cahced compressed video here.
                if FileManager.default.fileExists(atPath: compressedURL.path){
                    completion(compressedURL, nil)
                    return
                }
                
                self.compressVideo(inputURL: asset.url , outputURL: compressedURL, quality:quality) { (exportSession) in
                    guard let session = exportSession else {
                        return
                    }
                    switch session.status {
                    case .unknown:
                        completion(nil, CompressError.Failed)
                        break
                    case .waiting:
                        print("waiting")
                        break
                    case .exporting:
                        print("exporting")
                        break
                    case .completed:
                        completion(compressedURL, nil)
                    case .failed:
                        completion(nil, CompressError.Failed)
                        break
                    case .cancelled:
                        completion(nil, CompressError.Cancel)
                        break
                    default:
                        print("default")
                    }
                }
            }
        })
    }
    
    func compressVideo(inputURL: URL, outputURL: URL, quality:String, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        // 一次只執行一個影片壓縮
        self.compressQueue.addOperation {
            let urlAsset = AVURLAsset(url: inputURL, options: nil)
            guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: quality) else {
                handler(nil)
                
                return
            }
            self.exportSession = exportSession
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileType.mp4
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.exportAsynchronously { () -> Void in
                handler(exportSession)
                self.semaphore.signal()
            }
            self.semaphore.wait()
        }
    }
    
    func cancelExport(){
        self.semaphore.signal()
        self.exportSession?.cancelExport()
    }
}
