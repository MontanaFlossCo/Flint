//
//  EventKitPermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 30/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(EventKit)
import EventKit
#endif

/// Checks and authorises access to the EventKit on supported platforms
///
/// Support: iOS 6+, macOS 10.9+, watchOS 2+, tvOS ⛔️
class EventKitPermissionAdapter: SystemPermissionAdapter {
    static var isSupported: Bool {
#if !os(tvOS)
        if #available(iOS 6, macOS 10.9, watchOS 2, *) {
            return true
        } else {
            return false
        }
#else
        return false
#endif
    }

    static func createAdapters(for permission: SystemPermissionConstraint) -> [SystemPermissionAdapter] {
        return [EventKitPermissionAdapter(permission: permission)]
    }

    let permission: SystemPermissionConstraint
    let usageDescriptionKey: String = "NSEventKitUsageDescription"
#if canImport(EventKit)
    lazy var eventStore: EKEventStore = { EKEventStore() }()
    let entityType: EKEntityType
#endif

    var status: SystemPermissionStatus {
#if canImport(EventKit)
        if #available(iOS 6, macOS 10.9, watchOS 2, *) {
            return authStatusToPermissionStatus(EKEventStore.authorizationStatus(for: entityType))
        } else {
            return .unsupported
        }
#else
        return .unsupported
#endif
    }
    
    required init(permission: SystemPermissionConstraint) {
        // Deal, with this first as on some platforms we can't even import EventKit
        guard [.calendarEvents, .reminders].contains(permission) else {
            flintBug("Cannot create a EventKitPermissionAdapter with permission type \(permission)")
        }
#if canImport(EventKit)
        switch permission {
            case .calendarEvents: self.entityType = .event
            case .reminders: self.entityType = .reminder
            default:
                fatalError("Guard failed to protect from incorrect permision type")
        }
#endif
        self.permission = permission
    }
    
    func requestAuthorisation(completion: @escaping (_ adapter: SystemPermissionAdapter, _ status: SystemPermissionStatus) -> Void) {
#if !os(tvOS)
        guard status == .notDetermined else {
            return
        }
        
#if canImport(EventKit)
        eventStore.requestAccess(to: entityType) { (_, _) in
            completion(self, self.status)
        }
#endif
#else
        completion(self, .unsupported)
#endif
    }

#if canImport(EventKit)
    @available(iOS 6, macOS 10.9, watchOS 2, *)
    func authStatusToPermissionStatus(_ authStatus: EKAuthorizationStatus) -> SystemPermissionStatus {
#if os(tvOS)
        return .unsupported
#else
        switch authStatus {
            case .authorized: return .authorized
            case .denied: return .denied
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
        }
#endif
    }
#endif
}
