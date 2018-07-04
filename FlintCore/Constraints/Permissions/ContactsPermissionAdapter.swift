//
//  ContactsPermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 30/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(Contacts)
import Contacts
#endif

/// Defines the type of Contacts entity for which Flint will request access
public enum ContactsEntity: Hashable {
    case contacts
}

/// Checks and authorises access to the Contacts on supported platforms
///
/// Support: iOS 9+, macOS 10.11+, watchOS 2+, tvOS ⛔️
class ContactsPermissionAdapter: SystemPermissionAdapter {
    static var isSupported: Bool {
#if !os(tvOS)
        if #available(iOS 9, macOS 10.11, watchOS 2, *) {
            return true
        } else {
            return false
        }
#else
        return false
#endif
    }

    static func createAdapters(for permission: SystemPermissionConstraint) -> [SystemPermissionAdapter] {
        return [ContactsPermissionAdapter(permission: permission)]
    }

    let permission: SystemPermissionConstraint
    let usageDescriptionKey: String = "NSContactsUsageDescription"

    typealias AuthorizationStatusFunc = (_ entityType: Int) -> Int
    typealias RequestAccessFunc = (_ entityType: Int, _ completion: (_ granted: Bool, _ error: Error?) -> Void) -> Void

#if canImport(Contacts)
    lazy var contactStore: AnyObject = { try! instantiate(classNamed: "CNContactStore") }()
    let entityType: CNEntityType

    let getAuthorizationStatus: AuthorizationStatusFunc!
    lazy var requestAccess: RequestAccessFunc! = { try! dynamicBindIntAndBoolErrorOptionalClosureReturnVoid(toInstanceMethod: "requestAccessForEntityType:completionHandler:", on: contactStore) }()
#endif

    var status: SystemPermissionStatus {
#if canImport(Contacts)
        if #available(iOS 9, macOS 10.11, watchOS 2, *) {
            return authStatusToPermissionStatus(CNAuthorizationStatus(rawValue: getAuthorizationStatus(entityType.rawValue))!)
        } else {
            return .unsupported
        }
#else
        return .unsupported
#endif
    }
    
    required init(permission: SystemPermissionConstraint) {
        guard case let .contacts(entityType) = permission else {
            flintBug("Cannot create a ContactsPermissionAdapter with permission type \(permission)")
        }
        
#if canImport(Contacts)
        getAuthorizationStatus = try! dynamicBindIntArgsIntReturn(toStaticMethod: "authorizationStatusForEntityType:", on: "CNContactStore")
        
        switch entityType {
            case .contacts: self.entityType = .contacts
        }
#endif
        self.permission = permission
    }
    
    func requestAuthorisation(completion: @escaping (_ adapter: SystemPermissionAdapter, _ status: SystemPermissionStatus) -> Void) {
#if !os(tvOS)
        guard status == .notDetermined else {
            return
        }
        
#if canImport(Contacts)
        requestAccess(entityType.rawValue, { (_, _) in
            completion(self, self.status)
        })
#endif
#else
        completion(self, .unsupported)
#endif
    }

#if canImport(Contacts)
    @available(iOS 9, macOS 10.11, watchOS 2, *)
    func authStatusToPermissionStatus(_ authStatus: CNAuthorizationStatus) -> SystemPermissionStatus {
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
