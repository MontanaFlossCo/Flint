//
//  SiriKitPermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 15/05/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

#if canImport(Intents)
import Intents
#endif

#if canImport(Intents) && (os(iOS) || os(watchOS))
@objc
fileprivate protocol ProxyIntentPreferences {
    // These are not static as we call them on the class
    @available(iOS 10, watchOS 3.2, *)
    @objc
    func authorizationStatus() -> INSiriAuthorizationStatus

    @available(iOS 10, *)
    @objc(requestAuthorization:)
    func requestAuthorization(_ handler: @escaping (INSiriAuthorizationStatus) -> Void)
}
#endif

/// Support: iOS 10+, macOS ⛔️, watchOS ⛔️, tvOS ⛔️
class SiriKitPermissionAdapter: SystemPermissionAdapter {
    static var isSupported: Bool {
#if canImport(Intents)
        if #available(iOS 10, *) {
            let isLinked = libraryIsLinkedForClass("INPreferences")
            return isLinked
        } else {
            return false
        }
#else
        return false
#endif
        }
    
    static func createAdapters(for permission: SystemPermissionConstraint) -> [SystemPermissionAdapter] {
        return [SiriKitPermissionAdapter(permission: permission)]
    }
    
    let permission: SystemPermissionConstraint
    
#if canImport(Intents) && (os(iOS) || os(watchOS))
    @available(iOS 10, *)
    fileprivate lazy var preferencesClass: AnyObject = { NSClassFromString("INPreferences")! }()

    @available(iOS 10, *)
    fileprivate lazy var proxyPreferencesClass: ProxyIntentPreferences = { unsafeBitCast(self.preferencesClass, to: ProxyIntentPreferences.self) }()
#endif

    var status: SystemPermissionStatus {
#if canImport(Intents) && (os(iOS) || os(watchOS))
        if #available(iOS 10, watchOS 3.2, *) {
            return authStatusToPermissionStatus(proxyPreferencesClass.authorizationStatus())
        } else {
            return .unsupported
        }
#else
        return .unsupported
#endif
        }
    
    let usageDescriptionKey: String = "NSSiriUsageDescription"

    init(permission: SystemPermissionConstraint) {
        flintBugPrecondition(permission == .siriKit, "Cannot use SiriKitPermissionAdapter with: \(permission)")
        self.permission = permission
    }
    
    func requestAuthorisation(completion: @escaping (SystemPermissionAdapter, SystemPermissionStatus) -> Void) {
#if canImport(Intents) && (os(iOS) || os(watchOS))
        if #available(iOS 10, *) {
            proxyPreferencesClass.requestAuthorization() { [weak self] status in
                if let strongSelf = self {
                    completion(strongSelf, strongSelf.status)
                }
            }
        } else {
            completion(self, .unsupported)
        }
#else
        completion(self, .unsupported)
#endif
    }
    
#if canImport(Intents) && (os(iOS) || os(watchOS))
    @available(iOS 10, watchOS 3.2, *)
    func authStatusToPermissionStatus(_ authStatus: INSiriAuthorizationStatus) -> SystemPermissionStatus {
        switch authStatus {
            case .authorized: return .authorized
            case .denied: return .denied
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
        }
    }
#endif
}
