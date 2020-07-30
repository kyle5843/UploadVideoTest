//
//  MediaCellModel.swift
//  UploadMedia
//
//  Created by Kyle on 2020/7/4.
//  Copyright © 2020 All rights reserved.
//

import UIKit
import AVKit

protocol BaseCellModel {
    static var identifier: String { get }
    var indexPath:IndexPath? { get set }
    var cellHeight:CGFloat { get set }
    var hostVC:UIViewController? { get set}
    
    func didSelected()
}

class MediaCellModel: NSObject, BaseCellModel {
    static var identifier: String = "MediaCell"
    
    var identifier: String = MediaCellModel.identifier
    var indexPath: IndexPath?
    var cellHeight: CGFloat = 100
    weak var hostVC:UIViewController?
    var info:MediaInfo
    
    init(info:MediaInfo) {
        self.info = info
    }
    
    func didSelected() {
        let player = AVPlayer(url: self.info.mediaUrl)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        self.hostVC?.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }
}
