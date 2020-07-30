//
//  Dictionary+Extension.swift
//  UploadMedia
//
//  Created by Kyle on 2020/7/4.
//  Copyright © 2020 All rights reserved.
//

import Foundation

extension Dictionary {
    static func isValidity<T>(dict:Dictionary<T, Any>, typeMap:Dictionary<T, Any>) -> Bool {
        for (key, _) in typeMap {
            guard dict[key] != nil else {
                NSLog("type invalid")
                return false
            }
        }
        return true
    }
}


