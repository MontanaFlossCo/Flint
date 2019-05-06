//
//  AVCaptureDevicePermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 06/05/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import AVFoundation

#if os(iOS) || os(macOS)
@objc enum ProxyAVAuthorizationStatus: Int {
    case notDetermined
    case restricted
    case denied
    case authorized
}

@objc protocol ProxyCaptureDevice {
    // We don't mark these static as we call them on the class itself.
    @objc(authorizationStatusForMediaType:)
    func authorizationStatus(for mediaType: AVMediaType) -> ProxyAVAuthorizationStatus
    @objc(requestAccessForMediaType:completionHandler:)
    func requestAccess(for mediaType: AVMediaType, completionHandler handler: @escaping (Bool) -> Void)

}
#endif

/// Checks and authorises access to the AV Capture on supported platforms
///
/// Supports: iOS 7+, macOS 10.14+, watchOS ⛔️, tvOS ⛔️
class AVCaptureDevicePermissionAdapter: SystemPermissionAdapter {
    enum MediaType {
        case audio
        case video
    }
    
    static var isSupported: Bool {
#if os(iOS) || os(macOS)
        let isLinked = libraryIsLinkedForClass("AVCaptureDevice")
        return isLinked
#else
        return false
#endif
    }
    
    class func createAdapters(for permission: SystemPermissionConstraint) -> [SystemPermissionAdapter] {
        flintBug("AVCaptureDevicePermissionAdapter is to be used as a base class only")
    }

    let permission: SystemPermissionConstraint
    let usageDescriptionKey: String = "NSCameraUsageDescription"
    
#if os(iOS) || os(macOS)
    lazy var captureDeviceClass: AnyObject = { NSClassFromString("AVCaptureDevice")! }()
    lazy var proxyCaptureDeviceClass: ProxyCaptureDevice = { unsafeBitCast(self.captureDeviceClass, to: ProxyCaptureDevice.self) }()
#endif
    var status: SystemPermissionStatus {
#if os(iOS) || os(macOS)
        // Only macOS 10.14+ has camera permission APIs
        if #available(iOS 7, macOS 10.14, *) {
            switch proxyCaptureDeviceClass.authorizationStatus(for: .video) {
                case .authorized: return .authorized
                case .denied: return .denied
                case .notDetermined: return .notDetermined
                case .restricted: return .restricted
            }
        } else {
            // There are no permissions!
            return .authorized
        }
#else
        return .unsupported
#endif
    }

    let mediaType: MediaType
    var avMediaType: AVMediaType {
        switch mediaType {
            case .audio: return .audio
            case .video: return .video
        }
    }
    
    init(permission: SystemPermissionConstraint, mediaType: MediaType) {
        self.permission = permission
        self.mediaType = mediaType
    }
    
    func requestAuthorisation(completion: @escaping (_ adapter: SystemPermissionAdapter, _ status: SystemPermissionStatus) -> Void) {
#if os(iOS) || os(macOS)
        guard status == .notDetermined else {
            return
        }

        // Only macOS 10.14+ has camera permission APIs
        if #available(iOS 7, macOS 10.14, *) {
            proxyCaptureDeviceClass.requestAccess(for: avMediaType) { (granted: Bool) in
                completion(self, granted ? .authorized : .denied)
            }
        } else {
            completion(self, .authorized)
        }
#else
        completion(self, .unsupported)
#endif
    }
}
