//
//  UploadMediaViewModel.swift
//  UploadMedia
//
//  Created by Kyle on 2020/7/4.
//  Copyright © 2020. All rights reserved.
//

import UIKit
import Photos

class UploadMediaViewModel: NSObject {
    
    var videoInfos = Array<MediaCellModel>()

    func requestPrivacy(){
        if PHPhotoLibrary.authorizationStatus() == .notDetermined  {
            PHPhotoLibrary.requestAuthorization({status in })
        }
    }
    
    func upload() {
        UploadTaskManager.shared.addUploadTask(
            self.videoInfos.compactMap { mediaCellModel -> MediaInfo? in
            if mediaCellModel.info.state == .Ready ||
               mediaCellModel.info.state == .Failed {
                return mediaCellModel.info
            }
            return nil
        })
    }
}
