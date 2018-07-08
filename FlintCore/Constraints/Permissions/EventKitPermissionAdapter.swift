//
//  EventKitPermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 30/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

@objc fileprivate enum ProxyEntityType: Int {
    case event
    case reminder
}

@objc fileprivate enum ProxyAuthorizationStatus: Int {
    case notDetermined
    case restricted
    case denied
    case authorized
}

@objc fileprivate protocol ProxyEventStore {
    @objc(authorizationStatusForEntityType:)
    static func authorizationStatus(for entityType: ProxyEntityType) -> ProxyAuthorizationStatus

    @objc(requestAccessToEntityType:completion:)
    func requestAccess(to entityType: ProxyEntityType, completion: @escaping (Bool, Error?) -> Void)
}

/// Checks and authorises access to the EventKit on supported platforms
///
/// Support: iOS 6+, macOS 10.9+, watchOS 2+, tvOS ⛔️
class EventKitPermissionAdapter: SystemPermissionAdapter {
    static var isSupported: Bool {
#if !os(tvOS)
        if #available(iOS 6, macOS 10.9, watchOS 2, *) {
            let isLinked = libraryIsLinkedForClass("EKEventStore")
            return isLinked
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
    let usageDescriptionKey: String = "NSXXXXEventKitUsageDescription"

    fileprivate let entityType: ProxyEntityType
    lazy var eventStore: AnyObject? = { try? instantiate(classNamed: "EXXXXKEventStore") }()
    lazy fileprivate var proxyEventStore: ProxyEventStore? = {
        guard let eventStore = self.eventStore else {
            return nil
        }
        return unsafeBitCast(eventStore, to: ProxyEventStore.self)
    }()

    var status: SystemPermissionStatus {
        guard let proxyEventStore = proxyEventStore else {
            return .unsupported
        }
        
        if #available(iOS 6, macOS 10.9, watchOS 2, *) {
            return authStatusToPermissionStatus(type(of: proxyEventStore).authorizationStatus(for: entityType))
        } else {
            return .unsupported
        }
    }
    
    required init(permission: SystemPermissionConstraint) {
        // Deal, with this first as on some platforms we can't even import EventKit
        flintBugPrecondition([.calendarEvents, .reminders].contains(permission), "Cannot create a EventKitPermissionAdapter with permission type \(permission)")

        switch permission {
            case .calendarEvents: self.entityType = .event
            case .reminders: self.entityType = .reminder
            default:
                flintBug("Unsupported EventKit permission type")
        }

        self.permission = permission
    }
    
    func requestAuthorisation(completion: @escaping (_ adapter: SystemPermissionAdapter, _ status: SystemPermissionStatus) -> Void) {
#if !os(tvOS)
        guard status == .notDetermined else {
            return
        }
    
        guard let proxyEventStore = proxyEventStore else {
            completion(self, .unsupported)
            return
        }

        proxyEventStore.requestAccess(to: entityType) { (_, _) in
            completion(self, self.status)
        }
#else
        completion(self, .unsupported)
#endif
    }

    @available(iOS 6, macOS 10.9, watchOS 2, *)
    fileprivate func authStatusToPermissionStatus(_ authStatus: ProxyAuthorizationStatus) -> SystemPermissionStatus {
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
}
