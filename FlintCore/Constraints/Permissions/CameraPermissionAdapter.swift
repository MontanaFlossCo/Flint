//
//  CameraPermission.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
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

/// Checks and authorises access to the Camera on supported platforms
///
/// Supports: iOS 7+, macOS *, watchOS ⛔️, tvOS ⛔️
class CameraPermissionAdapter: SystemPermissionAdapter {
    static var isSupported: Bool {
#if os(iOS) || os(macOS)
        let isLinked = libraryIsLinkedForClass("AVCaptureDevice")
        return isLinked
#else
        return false
#endif
    }
    
    static func createAdapters(for permission: SystemPermissionConstraint) -> [SystemPermissionAdapter] {
        return [CameraPermissionAdapter(permission: permission)]
    }

    let permission: SystemPermissionConstraint
    let usageDescriptionKey: String = "NSCameraUsageDescription"

#if os(iOS) || os(macOS)
    lazy var captureDeviceClass: AnyObject = { NSClassFromString("AVCaptureDevice")! }()
    lazy var proxyCaptureDeviceClass: ProxyCaptureDevice = { unsafeBitCast(self.captureDeviceClass, to: ProxyCaptureDevice.self) }()
#endif
    var status: SystemPermissionStatus {
#if os(iOS)
        switch proxyCaptureDeviceClass.authorizationStatus(for: .video) {
            case .authorized: return .authorized
            case .denied: return .denied
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
        }
#elseif os(macOS)
        // There are no permissions!
        return .authorized
#else
        return .unsupported
#endif
    }

    required init(permission: SystemPermissionConstraint) {
        self.permission = permission
    }
    
    func requestAuthorisation(completion: @escaping (_ adapter: SystemPermissionAdapter, _ status: SystemPermissionStatus) -> Void) {
#if os(iOS)
        guard status == .notDetermined else {
            completion(self, .notDetermined)
            return
        }
        
        proxyCaptureDeviceClass.requestAccess(for: AVMediaType.video) { (granted: Bool) in
            completion(self, granted ? .authorized : .denied)
        }
#elseif os(macOS)
        completion(self, .authorized)
#else
        completion(self, .unsupported)
#endif
    }
}
