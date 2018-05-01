//
//  PhotoPermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(Photos)
import Photos
#endif

class PhotosPermissionAdapter: PermissionAdapter {
    let permission: SystemPermission = .photos
    let usageDescriptionKey: String = "NSPhotoLibraryUsageDescription"

    weak var delegate: PermissionAdapterDelegate?
    
    var status: PermissionStatus {
#if canImport(Photos)
        switch PHPhotoLibrary.authorizationStatus() {
            case .authorized: return .authorized
            case .denied: return .denied
            case .notDetermined: return .unknown
            case .restricted: return .restricted
        }
#else
        return .unsupported
#endif
    }
    
    func requestAuthorisation() {
#if canImport(Photos)
        guard status == .unknown else {
            return
        }
        
        PHPhotoLibrary.requestAuthorization({status in
            if status != .notDetermined {
                self.delegate?.permissionStatusDidChange(sender: self)
            }
        })
#endif
    }
}

