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

/// Checks and authorises access to the Photo library on supported platforms
class PhotosPermissionAdapter: SystemPermissionAdapter {
    let permission: SystemPermission = .photos
    let usageDescriptionKey: String = "NSPhotoLibraryUsageDescription"

    var status: SystemPermissionStatus {
#if canImport(Photos)
        if #available(iOS 8, tvOS 10, macOS 10.13, *) {
            return authStatusToPermissionStatus(PHPhotoLibrary.authorizationStatus())
        } else {
            return .unsupported
        }
#else
        return .unsupported
#endif
    }
    
    func requestAuthorisation(completion: @escaping (_ adapter: SystemPermissionAdapter, _ status: SystemPermissionStatus) -> Void) {
#if os(iOS)
#if canImport(Photos)
        guard status == .notDetermined else {
            return
        }
        
        PHPhotoLibrary.requestAuthorization({status in
            completion(self, self.authStatusToPermissionStatus(status))
        })
#endif
#endif
    }

#if canImport(Photos)
    @available(iOS 8, tvOS 10, macOS 10.13, *)
    func authStatusToPermissionStatus(_ authStatus: PHAuthorizationStatus) -> SystemPermissionStatus {
#if os(watchOS)
        return .unsupported
#else
        switch PHPhotoLibrary.authorizationStatus() {
            case .authorized: return .authorized
            case .denied: return .denied
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
        }
#endif
    }
#endif
}

