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
///
/// - see: Apple's document on user privacy for details of authorisations available
/// https://developer.apple.com/documentation/uikit/core_app/protecting_the_user_s_privacy
public enum SystemPermissionConstraint: Hashable, CustomStringConvertible {
    case camera
    case photos
    case microphone
    case location(usage: LocationUsage)
    case contacts(entity: ContactsEntity)
    case calendarEvents
    case reminders
    case motion
    case speechRecognition
    case siriKit
    case bluetooth

// The rest of these are "coming soon"
/*
    case bluetoothSharing
    case mediaLibrary
    case homeKit
    case health
*/

    public var description: String {
        switch self {
            case .camera: return "Camera"
            case .microphone: return "Microphone"
            case .photos: return "Photos"
            case .calendarEvents: return "Calendar Events"
            case .reminders: return "Reminders"
            case .motion: return "Motion"
            case .speechRecognition: return "Speech Recognition"
            case .siriKit: return "Siri Kit"
            case .bluetooth: return "Bluetooth Peripheral"
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
            case .camera,
                 .microphone,
                 .calendarEvents,
                 .reminders,
                 .photos,
                 .speechRecognition,
                 .siriKit,
                 .bluetooth,
                 .motion:
                return ""
            case .location(let usage): return "usage \(usage)"
            case .contacts(let entity): return "entity \(entity)"
        }
    }
}
