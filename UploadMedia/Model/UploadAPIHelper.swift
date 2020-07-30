//
//  UploadAPIHelper.swift
//  UploadMedia
//
//  Created by Kyle on 2020/7/4.
//  Copyright © 2020. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage

enum UploadError:Error {
    case DataFailed
    case Cancel
}

class UploadAPIHelper: NSObject {
    
    static let shared = UploadAPIHelper()
    
    //已移除有效gmail, 程式碼僅供測試
    private let loginEmail: String = "test@gmail.com"
    private let loginPassword: String = "123456"
    private let filePath: String = "kylePath"
    
    override init() {
        super.init()
        self.login()
    }
    
    private func login() {
        Auth.auth()
            .signIn(withEmail: loginEmail, password: loginPassword) { result, _ in
        }
    }
    
    func uploadThumbnail(_ image:UIImage, completion:@escaping (Error?) -> Void) -> StorageUploadTask? {
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            NSLog("Failed")
            completion(UploadError.DataFailed)
            return nil
        }
        
        let fileName = "\(Date().timeIntervalSince1970).jpg"
        let rootRef = Storage.storage().reference().child("user").child(self.loginEmail)
        let path = rootRef.child(self.filePath).child(fileName)
        return path.putData(data, metadata: nil) { (nil, maybeError) in
            if let error = maybeError {
                let message = error.localizedDescription
                NSLog("Error: \(message)")
            }
            completion(maybeError)
        }
    }
    
    func uploadCompressedVideo(_ url:URL, completion:@escaping (Error?) -> Void) -> StorageUploadTask? {
           
           let fileName = "\(Date().timeIntervalSince1970).mp4"
           let rootRef = Storage.storage().reference().child("user").child(self.loginEmail)
           let path = rootRef.child(self.filePath).child(fileName)
           return path.putFile(from: url, metadata: nil) { (nil, maybeError) in
               if let error = maybeError {
                   NSLog("Error: \(error.localizedDescription)")
               }
               completion(maybeError)
           }
       }
}
