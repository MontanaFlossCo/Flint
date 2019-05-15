//
//  BluetoothPeripheralPermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 15/05/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import CoreBluetooth

@objc protocol ProxyPeripheralManager {
    /// Non-static as we are proxying the class, not an instance
    @objc
    func authorizationStatus() -> CBPeripheralManagerAuthorizationStatus
}

/// Checks and authorises access to the user's location on supported platforms
///
/// Supports: iOS 7+, macOS 10.9+, watchOS 2+, tvOS 9+
@objc class BluetoothPeripheralPermissionAdapter: NSObject, SystemPermissionAdapter {
    static var isSupported: Bool {
        if #available(iOS 7, macOS 10.9, watchOS 2, tvOS 9, *) {
            let isLinked = libraryIsLinkedForClass("CBPeripheralManager")
            return isLinked
        } else {
            return false
        }
    }
    
    static func createAdapters(for permission: SystemPermissionConstraint) -> [SystemPermissionAdapter] {
        return [BluetoothPeripheralPermissionAdapter(permission: .bluetooth)]
    }

    lazy var peripheralManagerClass: AnyObject = { NSClassFromString("CBPeripheralManager")! }()
    lazy var proxyPeripheralManagerClass: ProxyPeripheralManager = { unsafeBitCast(self.peripheralManagerClass, to: ProxyPeripheralManager.self) }()

    let permission: SystemPermissionConstraint
    let usageDescriptionKey = "NSBluetoothPeripheralUsageDescription"

    var status: SystemPermissionStatus {
        return authStatusToPermissionStatus(proxyPeripheralManagerClass.authorizationStatus())
    }
    
    required init(permission: SystemPermissionConstraint) {
        guard case .bluetooth = permission else {
            flintBug("Cannot use LocationPermissionAdapter with \(permission)")
        }

        self.permission = permission

        super.init()
    }
    
    func requestAuthorisation(completion: @escaping (_ adapter: SystemPermissionAdapter, _ status: SystemPermissionStatus) -> Void) {
        completion(self, .unsupported)
    }

    // MARK: Internals
    
    @available(iOS 7, macOS 10.9, watchOS 2, tvOS 9, *)
    func authStatusToPermissionStatus(_ status: CBPeripheralManagerAuthorizationStatus) -> SystemPermissionStatus {
        switch status {
            case .denied: return .denied
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
            case .authorized: return .authorized
        }
    }
}
