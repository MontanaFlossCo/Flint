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
/// Supports: iOS 7+, macOS 10.14+, watchOS ⛔️, tvOS ⛔️
class CameraPermissionAdapter: AVCaptureDevicePermissionAdapter {
    override class func createAdapters(for permission: SystemPermissionConstraint) -> [SystemPermissionAdapter] {
        return [CameraPermissionAdapter(permission: permission)]
    }

    required init(permission: SystemPermissionConstraint) {
        super.init(permission: permission, mediaType: .video)
    }
}
