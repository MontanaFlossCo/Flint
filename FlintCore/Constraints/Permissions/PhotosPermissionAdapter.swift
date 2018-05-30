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
///
/// Supports: iOS 8+, macOS 10.13+, watchOS ⛔️, tvOS 10+
class PhotosPermissionAdapter: SystemPermissionAdapter {
    static var isSupported: Bool {
#if os(watchOS)
        return false
#else
        if #available(iOS 8, macOS 10.13, tvOS 10, *) {
            return true
        } else {
            return false
        }
#endif
    }

    static func createAdapters(for permission: SystemPermissionConstraint) -> [SystemPermissionAdapter] {
        return [PhotosPermissionAdapter(permission: permission)]
    }

    let permission: SystemPermissionConstraint
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
    
    required init(permission: SystemPermissionConstraint) {
        self.permission = permission
    }
    
    func requestAuthorisation(completion: @escaping (_ adapter: SystemPermissionAdapter, _ status: SystemPermissionStatus) -> Void) {
#if canImport(Photos)
        guard status == .notDetermined else {
            return
        }
        
        if #available(iOS 8, tvOS 10, macOS 10.13, *) {
            PHPhotoLibrary.requestAuthorization({status in
                completion(self, self.authStatusToPermissionStatus(status))
            })
        } else {
                completion(self, .unsupported)
        }
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

