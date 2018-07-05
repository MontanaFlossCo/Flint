//
//  LocationPermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import CoreLocation

@objc protocol ProxyLocationManager {
    @objc static func authorizationStatus() -> CLAuthorizationStatus

    @objc var delegate: CLLocationManagerDelegate? { get set }

    @objc func requestWhenInUseAuthorization()
    @objc func requestAlwaysAuthorization()
}

/// Checks and authorises access to the user's location on supported platforms
///
/// Supports: iOS 2+, macOS 10.6+, watchOS 2+, tvOS 9+
@objc class LocationPermissionAdapter: NSObject, SystemPermissionAdapter, CLLocationManagerDelegate {
    static var isSupported: Bool {
        if #available(iOS 2, macOS 10.6, watchOS 2, tvOS 9, *) {
            let isLinked = libraryIsLinkedForClass("CLLocationManager")
            return isLinked
        } else {
            return false
        }
    }
    
    static func createAdapters(for permission: SystemPermissionConstraint) -> [SystemPermissionAdapter] {
        var results: [SystemPermissionAdapter] = []
#if canImport(CoreLocation)
        // One for whenInUse checking
        results.append(LocationPermissionAdapter(permission: .location(usage: .whenInUse)))
#if os(iOS) || os(watchOS)
        // One for always checking
        results.append(LocationPermissionAdapter(permission: .location(usage: .always)))
#endif
#endif
        return results
    }

    lazy var locationManager: AnyObject = { try! instantiate(classNamed: "CLLocationManager") }()
    lazy var proxyLocationManager: ProxyLocationManager = { unsafeBitCast(self.locationManager, to: ProxyLocationManager.self) }()

    let permission: SystemPermissionConstraint
    let usageDescriptionKey: String
    var pendingCompletions: [(_ adapter: SystemPermissionAdapter, _ status: SystemPermissionStatus) -> Void] = []
    var statusBeforeRequesting: CLAuthorizationStatus?

    var status: SystemPermissionStatus {
        return authStatusToPermissionStatus(type(of: proxyLocationManager).authorizationStatus())
    }
    
    required init(permission: SystemPermissionConstraint) {
        guard case let .location(usage) = permission else {
            flintBug("Cannot use LocationPermissionAdapter with \(permission)")
        }

#if !os(iOS)
        if .always == usage {
            fatalError("Location usage cannot be 'always' on this platform.")
        }
#endif
        self.permission = permission

        switch usage {
            case .whenInUse: usageDescriptionKey = "NSLocationWhenInUseUsageDescription"
            case .always: usageDescriptionKey = "NSLocationAlwaysUsageDescription"
        }
        
        super.init()
        
        proxyLocationManager.delegate = self
    }
    
    func requestAuthorisation(completion: @escaping (_ adapter: SystemPermissionAdapter, _ status: SystemPermissionStatus) -> Void) {
        guard status == .notDetermined else {
            completion(self, status)
            return
        }
        
        // Keep this so that we can detect actual changes to status, not the lies
        // that CLLocationManager tells us
        statusBeforeRequesting = CLLocationManager.authorizationStatus()
        
#if os(macOS)
        // macOS does not have authorization functions
        completion(self, .authorized)
        return
#elseif os(iOS)
        switch permission {
            case .location(usage: .always):
                pendingCompletions.append(completion)
                FlintInternal.logger?.debug("Location permission adapter requesting 'always' authorization")
                proxyLocationManager.requestAlwaysAuthorization()
            case .location(usage: .whenInUse):
                pendingCompletions.append(completion)
                FlintInternal.logger?.debug("Location permission adapter requesting 'when in use' authorization")
                proxyLocationManager.requestWhenInUseAuthorization()
            default:
                flintBug("Incorrect permission type: \(permission)")
        }
#else
        flintUsageError("Location usage cannot be 'always' on this platform.")
#endif
    }

    // MARK: Location Manager delegate

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard statusBeforeRequesting != status else {
            return
        }
        FlintInternal.logger?.debug("Location permission adapter received status change: \(status)")
        for completion in pendingCompletions {
            completion(self, authStatusToPermissionStatus(status))
        }
    }
    
    // MARK: Internals
    
    func authStatusToPermissionStatus(_ status: CLAuthorizationStatus) -> SystemPermissionStatus {
        /// !!! TODO: Threading!
        switch status {
            case .denied: return .denied
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
            case .authorizedAlways:
                if case let .location(usage) = permission {
                    return usage == .always ? .authorized : .denied
                } else {
                    flintBug("Location adapter has wrong type of permission")
                }
            case .authorizedWhenInUse:
                if case let .location(usage) = permission {
                    return usage == .whenInUse ? .authorized : .denied
                } else {
                    flintBug("Location adapter has wrong type of permission")
                }
        }
    }
}

