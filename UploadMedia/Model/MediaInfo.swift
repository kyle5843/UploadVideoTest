//
//  MediaInfo.swift
//  UploadMedia
//
//  Created by Kyle on 2020/7/4.
//  Copyright © 2020. All rights reserved.
//

import UIKit
import Photos
import RxCocoa
import RxSwift

class MediaInfo: NSObject {
    
    var title:BehaviorRelay<String> = BehaviorRelay<String>(value: UploadState.Ready.rawValue)
    var state:UploadState = .Ready {
        didSet {
            title.accept(state.rawValue)
        }
    }
    var uploadProgress:Double = -1 {
        didSet {
            let str = String(format: "%.2f", uploadProgress)
            let progress = uploadProgress > 0 ? " \(str)%" : ""
            title.accept(state.rawValue + progress)
        }
    }
    var mediaType:String
    var asset:PHAsset
    var mediaUrl:URL
    var thunmbNail:UIImage? {
        get {
            let key = mediaUrl.absoluteString
            if let image = key.cachedImage {
                return image
            } else {
                let image = self.asset.thumbnail(CGSize.init(width: 300, height: 300))
                ImageCache.sharedCache.setObject(image, forKey:key as NSString)
                return image
            }
        }
    }
    
    init(info:[UIImagePickerController.InfoKey : Any]) {
        
        self.mediaType = info[UIImagePickerController.InfoKey.mediaType] as! String
        self.mediaUrl  = info[UIImagePickerController.InfoKey.mediaURL] as! URL
        self.asset     = info[UIImagePickerController.InfoKey.phAsset] as! PHAsset
        
        super.init()
    }

    static func typeMap() -> Dictionary<UIImagePickerController.InfoKey, Any>{
        return [UIImagePickerController.InfoKey.mediaType    : String.self,
                UIImagePickerController.InfoKey.phAsset      : PHAsset.self,
                UIImagePickerController.InfoKey.mediaURL     : URL.self,
               ]
    }
}
