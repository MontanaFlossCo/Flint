//
//  SystemPermission.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Defines a system permission that conditional features can use as a constraint.
public enum SystemPermissionConstraint: Hashable, CustomStringConvertible {
    case camera
    case photos
    case location(usage: LocationUsage)

// The rest of these are "coming soon"
/*
    case contacts
    case calendars
    case reminders
    case homeKit
    case health
    case motionAndFitness
    case speechRecognition
    case bluetoothSharing
    case mediaLibrary
*/

    public var description: String {
        switch self {
            case .camera: return "Camera"
            case .photos: return "Photos"
            case .location(let usage):
                switch usage {
                    case .whenInUse: return "Location when in use"
                    case .always: return "Location always"
                }
        }
    }
}

