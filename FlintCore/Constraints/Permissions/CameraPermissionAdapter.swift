//
//  CameraPermission.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif

/// Checks and authorises access to the Camera on supported platforms
class CameraPermissionAdapter: SystemPermissionAdapter {
    let permission: SystemPermission = .camera
    let usageDescriptionKey: String = "NSCameraUsageDescription"

    var status: SystemPermissionStatus {
#if os(iOS)
#if canImport(AVFoundation)
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: return .authorized
            case .denied: return .denied
            case .notDetermined: return .unknown
            case .restricted: return .restricted
        }
#else
        return .unsupported
#endif
#elseif os(macOS)
        return .authorized
#else
        return .unsupported
#endif
    }

    func requestAuthorisation() {
#if os(iOS)
#if canImport(AVFoundation)
        guard status == .unknown else {
            return
        }
        
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                //access granted
            } else {

            }
        }
#endif
#endif
    }
}
