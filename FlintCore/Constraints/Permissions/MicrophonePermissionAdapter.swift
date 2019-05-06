//
//  MicrophonePermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 06/05/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import AVFoundation

/// Checks and authorises access to the Camera on supported platforms
///
/// Supports: iOS 7+, macOS 10.14+, watchOS ⛔️, tvOS ⛔️
class MicrophonePermissionAdapter: AVCaptureDevicePermissionAdapter {
    override class func createAdapters(for permission: SystemPermissionConstraint) -> [SystemPermissionAdapter] {
        return [MicrophonePermissionAdapter(permission: permission)]
    }

    required init(permission: SystemPermissionConstraint) {
        super.init(permission: permission, mediaType: .audio)
    }
}
