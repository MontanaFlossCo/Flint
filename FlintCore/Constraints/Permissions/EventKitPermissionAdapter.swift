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
            let isLinked = libraryIsLinkedForClass(EventKitPermissionAdapter.storeClassName)
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
    let usageDescriptionKey: String
    
    typealias AuthorizationStatusFunc = (_ entityType: Int) -> Int
    typealias RequestAccessFunc = (_ entityType: Int, _ completion: (_ granted: Bool, _ error: Error?) -> Void) -> Void

    static private let storeClassName = "EKEventStore"
    
    private let entityType: ProxyEntityType
    private lazy var eventStore: AnyObject? = { try? instantiate(classNamed: EventKitPermissionAdapter.storeClassName) }()
    private lazy var getAuthorizationStatus: AuthorizationStatusFunc? = {
        return try? dynamicBindIntArgsIntReturn(toStaticMethod: "authorizationStatus", on: EventKitPermissionAdapter.storeClassName)
    }()
    private lazy var requestAuthorization: RequestAccessFunc? = {
        if let store = eventStore {
            return try? dynamicBindIntAndBoolErrorOptionalClosureReturnVoid(toInstanceMethod: "requestAccessToEntityType:completion:", on: store)
        } else {
            return nil
        }
    }()

    var status: SystemPermissionStatus {
        guard let getAuthorizationStatus = getAuthorizationStatus else {
            return .unsupported
        }
        
        if #available(iOS 6, macOS 10.9, watchOS 2, *) {
            return authStatusToPermissionStatus(ProxyAuthorizationStatus(rawValue: getAuthorizationStatus(entityType.rawValue))!)
        } else {
            return .unsupported
        }
    }
    
    required init(permission: SystemPermissionConstraint) {
        // Deal, with this first as on some platforms we can't even import EventKit
        flintBugPrecondition([.calendarEvents, .reminders].contains(permission), "Cannot create a EventKitPermissionAdapter with permission type \(permission)")

        switch permission {
            case .calendarEvents:
                entityType = .event
                usageDescriptionKey = "NSCalendarsUsageDescription"
            case .reminders:
                entityType = .reminder
                usageDescriptionKey = "NSRemindersUsageDescription"
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
    
        guard let requestAuthorization = requestAuthorization else {
            completion(self, .unsupported)
            return
        }

        requestAuthorization(entityType.rawValue, { (_, _) in
            completion(self, self.status)
        })
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
