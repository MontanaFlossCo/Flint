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
#if os(iOS)
#if canImport(Photos)
        return authStatusToPermissionStatus(PHPhotoLibrary.authorizationStatus())
#else
        return .unsupported
#endif
#elseif os(macOS)
        return .authorized
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

    func authStatusToPermissionStatus(_ authStatus: PHAuthorizationStatus) -> SystemPermissionStatus {
        switch PHPhotoLibrary.authorizationStatus() {
            case .authorized: return .authorized
            case .denied: return .denied
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
        }
    }
}

