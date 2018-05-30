//
//  CameraPermission.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import AVFoundation

/// Checks and authorises access to the Camera on supported platforms
///
/// Supports: iOS 7+, macOS *, watchOS ⛔️, tvOS ⛔️
class CameraPermissionAdapter: SystemPermissionAdapter {
    static var isSupported: Bool {
#if os(iOS) || os(macOS)
        return true
#else
        return false
#endif
    }
    
    static func createAdapters(for permission: SystemPermissionConstraint) -> [SystemPermissionAdapter] {
        return [CameraPermissionAdapter(permission: permission)]
    }

    let permission: SystemPermissionConstraint
    let usageDescriptionKey: String = "NSCameraUsageDescription"

    var status: SystemPermissionStatus {
#if os(iOS)
        switch AVCaptureDevice.authorizationStatus(for: .video) {
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
        
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { (granted: Bool) in
            completion(self, granted ? .authorized : .denied)
        }
#elseif os(macOS)
        completion(self, .authorized)
#else
        completion(self, .unsupported)
#endif
    }
}
