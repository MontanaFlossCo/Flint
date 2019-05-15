//
//  MediaLibraryPermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 15/05/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(MediaPlayer)
import MediaPlayer
#endif

#if canImport(MediaPlayer) && os(iOS)
@objc
fileprivate protocol ProxyMediaLibrary {
    // These are not static as we call them on the class
    @available(iOS 9.3, *)
    @objc
    func authorizationStatus() -> MPMediaLibraryAuthorizationStatus

    @available(iOS 9.3, *)
    @objc(requestAuthorization:)
    func requestAuthorization(_ handler: @escaping (MPMediaLibraryAuthorizationStatus) -> Void)
}
#endif

/// Support: iOS 9.3+, macOS ⛔️, watchOS ⛔️, tvOS ⛔️
class MediaLibraryPermissionAdapter: SystemPermissionAdapter {
    static var isSupported: Bool {
#if canImport(MediaPlayer) && os(iOS)
        if #available(iOS 9.3, *) {
            let isLinked = libraryIsLinkedForClass("MPMediaLibrary")
            return isLinked
        } else {
            return false
        }
#else
        return false
#endif
        }
    
    static func createAdapters(for permission: SystemPermissionConstraint) -> [SystemPermissionAdapter] {
        return [SpeechRecognitionPermissionAdapter(permission: permission)]
    }
    
    let permission: SystemPermissionConstraint
    
#if canImport(MediaPlayer) && os(iOS)
    @available(iOS 9.3, *)
    private lazy var mediaLibraryClass: AnyObject = { NSClassFromString("MPMediaLibrary")! }()
    
    @available(iOS 9.3, *)
    private lazy var proxyMediaLibraryClass: ProxyMediaLibrary = { unsafeBitCast(self.mediaLibraryClass, to: ProxyMediaLibrary.self) }()
#endif

    var status: SystemPermissionStatus {
#if canImport(MediaPlayer) && os(iOS)
        if #available(iOS 9.3, *) {
            return authStatusToPermissionStatus(proxyMediaLibraryClass.authorizationStatus())
        } else {
            return .unsupported
        }
#else
        return .unsupported
#endif
        }
    
    let usageDescriptionKey: String = "NSAppleMusicUsageDescription"

    init(permission: SystemPermissionConstraint) {
        flintBugPrecondition(permission == .mediaLibrary, "Cannot use MediaLibraryPermissionAdapter with: \(permission)")
        self.permission = permission
    }
    
    func requestAuthorisation(completion: @escaping (SystemPermissionAdapter, SystemPermissionStatus) -> Void) {
#if canImport(MediaPlayer) && os(iOS)
        if #available(iOS 9.3, *) {
            proxyMediaLibraryClass.requestAuthorization() { [weak self] status in
                if let strongSelf = self {
                    completion(strongSelf, strongSelf.status)
                }
            }
        } else {
            completion(self, .unsupported)
        }
#else
        completion(self, .unsupported)
#endif
    }
    
#if canImport(MediaPlayer) && os(iOS)
    @available(iOS 9.3, *)
    func authStatusToPermissionStatus(_ authStatus: MPMediaLibraryAuthorizationStatus) -> SystemPermissionStatus {
        switch authStatus {
            case .authorized: return .authorized
            case .denied: return .denied
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
        }
    }
#endif
}

