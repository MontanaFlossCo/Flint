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

    static func createAdapters() -> [SystemPermissionAdapter] {
        return [ContactsPermissionAdapter(permission: .contacts(entity: .contacts))]
    }

    let permission: SystemPermissionConstraint
    let usageDescriptionKey: String = "NSPhotoLibraryUsageDescription"
    let contactStore = CNContactStore()
    let entityType: CNEntityType

    var status: SystemPermissionStatus {
#if canImport(Photos)
        if #available(iOS 9, macOS 10.11, watchOS 2, *) {
            return authStatusToPermissionStatus(CNContactStore.authorizationStatus(for: entityType))
        } else {
            return .unsupported
        }
#endif
    }
    
    required init(permission: SystemPermissionConstraint) {
        guard case let .contacts(entityType) = permission else {
            preconditionFailure("Cannot create a ContactsPermissionAdapter with permission type \(permission)")
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
        
        contactStore.requestAccess(for: .contacts) { (_, _) in
            completion(self, self.status)
        }
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
