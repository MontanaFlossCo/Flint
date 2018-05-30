//
//  SystemPermission.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Defines a system permission that conditional features can use as a constraint.
///
/// - note: Any associated values for permission variants must use Flint or foundation types because
/// we cannot have permissions force dependency on any given framework.
public enum SystemPermissionConstraint: Hashable, CustomStringConvertible {
    case camera
    case photos
    case location(usage: LocationUsage)
    case contacts(entity: ContactsEntity)

// The rest of these are "coming soon"
/*
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
            case .contacts(let entity):
                switch entity {
                    case .contacts: return "Contacts"
                }
        }
    }
}

extension SystemPermissionConstraint: FeatureConstraint {
    public var name: String { return String(describing: self) }
    public var parametersDescription: String {
        switch self {
            case .camera: return ""
            case .location(let usage): return "usage \(usage)"
            case .contacts(_): return ""
            case .photos: return ""
        }
    }
}
