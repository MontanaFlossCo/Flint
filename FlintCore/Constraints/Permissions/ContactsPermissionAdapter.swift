//
//  ContactsPermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 30/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

@objc fileprivate enum ProxyEntityType: Int {
    case contacts
}

@objc fileprivate enum ProxyAuthorizationStatus: Int {
    case notDetermined
    case restricted
    case denied
    case authorized
}

/// Checks and authorises access to the Contacts on supported platforms
///
/// Support: iOS 9+, macOS 10.11+, watchOS 2+, tvOS ⛔️
class ContactsPermissionAdapter: SystemPermissionAdapter {
    static var isSupported: Bool {
#if !os(tvOS)
        if #available(iOS 9, macOS 10.11, watchOS 2, *) {
            // Do this in case it is not auto-linked on all supported platforms
            let isLinked = libraryIsLinkedForClass("CNContactStore")
            return isLinked
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

    private let entityType: ProxyEntityType
    private lazy var contactStore: AnyObject? = { try? instantiate(classNamed: "CNContactStore") }()
    private lazy var getAuthorizationStatus: AuthorizationStatusFunc? = {
        return try? dynamicBindIntArgsIntReturn(toStaticMethod: "authorizationStatusForEntityType:", on: "CNContactStore")
    }()
    private lazy var requestAuthorization: RequestAccessFunc? = {
        if let store = contactStore {
            return try? dynamicBindIntAndBoolErrorOptionalClosureReturnVoid(toInstanceMethod: "requestAccessForEntityType:completionHandler:", on: store)
        } else {
            return nil
        }
    }()

    var status: SystemPermissionStatus {
        // Verify this first, we can't check availability at compile as it adds a libswiftContacts.dylib dependency
        guard let getAuthorizationStatus = getAuthorizationStatus else {
            return .unsupported
        }
        
        if #available(iOS 9, macOS 10.11, watchOS 2, *) {
            return authStatusToPermissionStatus(ProxyAuthorizationStatus(rawValue: getAuthorizationStatus(entityType.rawValue))!)
        } else {
            return .unsupported
        }
    }
    
    required init(permission: SystemPermissionConstraint) {
        guard case let .contacts(entityType) = permission else {
            flintBug("Cannot create a ContactsPermissionAdapter with permission type \(permission)")
        }
        
        switch entityType {
            case .contacts: self.entityType = .contacts
        }

        self.permission = permission
    }
    
    func requestAuthorisation(completion: @escaping (_ adapter: SystemPermissionAdapter, _ status: SystemPermissionStatus) -> Void) {
#if !os(tvOS)
        guard status == .notDetermined else {
            return
        }
        
        // Verify this first, we can't check availability at compile as it adds a libswiftContacts.dylib dependency
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

    @available(iOS 9, macOS 10.11, watchOS 2, *)
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
