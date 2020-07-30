//
//  PHAsset+Extension.swift
//  UploadMedia
//
//  Created by Kyle on 2020/7/4.
//  Copyright © 2020 All rights reserved.
//

import Photos
import UIKit

extension PHAsset {
    
    func thumbnail(_ size:CGSize) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: self, targetSize: size, contentMode: .aspectFit, options: option, resultHandler: { (result, info) -> Void in
            thumbnail = result!
        })
        return thumbnail
    }
}
