//
//  ImageCache.swift
//  UploadMedia
//
//  Created by Kyle on 2020/7/4.
//  Copyright © 2020 All rights reserved.
//

import UIKit

class ImageCache {
    
    static let sharedCache: NSCache = { () -> NSCache<NSString, AnyObject> in
        let cache = NSCache<NSString, AnyObject>()
        cache.name = "ImageCache"
        cache.countLimit = 200 // Max 200 images in memory.
        cache.totalCostLimit = 80*1024*1024 // Max 80MB used.
        return cache
    }()
    
}

extension URL {
    var cachedImage: UIImage? {
        return ImageCache.sharedCache.object(
            forKey: absoluteString as NSString) as? UIImage
    }
}

extension String {
    var cachedImage: UIImage? {
        return ImageCache.sharedCache.object(
            forKey: self as NSString) as? UIImage
    }
}
