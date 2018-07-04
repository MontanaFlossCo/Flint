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
    typealias AuthorizationStatusFunc = (_ entityType: UInt) -> Int
    typealias RequestAccessFunc = (_ entityType: UInt, _ completion: (_ granted: Bool, _ error: Error?) -> Void) -> Void

    let entityType: EKEntityType
    let getAuthorizationStatus: AuthorizationStatusFunc!
    lazy var requestAccess: RequestAccessFunc! = { try! dynamicBindUIntAndBoolErrorOptionalClosureReturnVoid(toInstanceMethod: "requestAccessForEntityType:completion:", on: eventStore) }()
    lazy var eventStore: AnyObject = { try! instantiate(classNamed: "EKEventStore") }()
#endif

    var status: SystemPermissionStatus {
#if canImport(EventKit)
        if #available(iOS 6, macOS 10.9, watchOS 2, *) {
            return authStatusToPermissionStatus(EKAuthorizationStatus(rawValue: getAuthorizationStatus(entityType.rawValue))!)
        } else {
            return .unsupported
        }
#else
        return .unsupported
#endif
    }
    
    required init(permission: SystemPermissionConstraint) {
        // Deal, with this first as on some platforms we can't even import EventKit
        flintBugPrecondition([.calendarEvents, .reminders].contains(permission), "Cannot create a EventKitPermissionAdapter with permission type \(permission)")

#if canImport(EventKit)
        getAuthorizationStatus = try! dynamicBindUIntArgsIntReturn(toStaticMethod: "authorizationStatusForEntityType:", on: "EKEventStore")
        
        switch permission {
            case .calendarEvents: self.entityType = .event
            case .reminders: self.entityType = .reminder
            default:
                flintBug("Unsupported EventKit permission type")
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
        requestAccess(entityType.rawValue) { (_, _) in
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
