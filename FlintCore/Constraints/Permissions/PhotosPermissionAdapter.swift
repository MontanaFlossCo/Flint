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

 @objc enum ProxyPHAuthorizationStatus: Int {
    case notDetermined
    case restricted
    case denied
    case authorized
}

@objc protocol ProxyPhotoLibrary {
    // Don't declare these as static, we call them on the clasws
    func authorizationStatus() -> ProxyPHAuthorizationStatus
    
    @objc(requestAuthorization:)
    func requestAuthorization(_ handler: @escaping (ProxyPHAuthorizationStatus) -> Void)
}

/// Checks and authorises access to the Photo library on supported platforms
///
/// Supports: iOS 8+, macOS 10.13+, watchOS ⛔️, tvOS 10+
class PhotosPermissionAdapter: SystemPermissionAdapter {
    static var isSupported: Bool {
#if os(watchOS)
        return false
#else
        if #available(iOS 8, macOS 10.13, tvOS 10, *) {
            let isLinked = libraryIsLinkedForClass("PHPhotoLibrary")
            return isLinked
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

    lazy var photoLibrary: AnyObject = { NSClassFromString("PHPhotoLibrary")! }()
    lazy var proxyPhotoLibrary: ProxyPhotoLibrary = { unsafeBitCast(self.photoLibrary, to: ProxyPhotoLibrary.self) }()
    
    var status: SystemPermissionStatus {
#if canImport(Photos)
        if #available(iOS 8, tvOS 10, macOS 10.13, *) {
            return authStatusToPermissionStatus(proxyPhotoLibrary.authorizationStatus())
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
            proxyPhotoLibrary.requestAuthorization({status in
                completion(self, self.authStatusToPermissionStatus(status))
            })
        } else {
                completion(self, .unsupported)
        }
#endif
    }

#if canImport(Photos)
    @available(iOS 8, tvOS 10, macOS 10.13, *)
    func authStatusToPermissionStatus(_ authStatus: ProxyPHAuthorizationStatus) -> SystemPermissionStatus {
#if os(watchOS)
        return .unsupported
#else
        switch proxyPhotoLibrary.authorizationStatus() {
            case .authorized: return .authorized
            case .denied: return .denied
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
        }
#endif
    }
#endif
}

