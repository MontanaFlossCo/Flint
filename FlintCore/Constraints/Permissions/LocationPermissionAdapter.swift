//
//  LocationPermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import CoreLocation

/// Checks and authorises access to the user's location on supported platforms
/// !!! TODO: What about macOS?
@objc class LocationPermissionAdapter: NSObject, SystemPermissionAdapter, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    
    let permission: SystemPermissionConstraint
    let usageDescriptionKey: String = "NSLocationWhenInUseUsageDescription"
    var pendingCompletions: [(_ adapter: SystemPermissionAdapter, _ status: SystemPermissionStatus) -> Void] = []
    
    var status: SystemPermissionStatus {
        return authStatusToPermissionStatus(CLLocationManager.authorizationStatus())
    }
    
    public init(usage: LocationUsage) {
#if !os(iOS)
        if .always == usage {
            fatalError("Location usage cannot be 'always' on this platform.")
        }
#endif
        switch usage {
            case .always: permission = .location(usage: .always)
            case .whenInUse: permission = .location(usage: .whenInUse)
        }
        super.init()
        locationManager.delegate = self
    }
    
    func requestAuthorisation(completion: @escaping (_ adapter: SystemPermissionAdapter, _ status: SystemPermissionStatus) -> Void) {
        guard status == .notDetermined else {
            completion(self, status)
            return
        }
        
#if os(macOS)
        // macOS does not have authorization functions
        completion(self, .authorized)
        return
#elseif os(iOS)
        switch permission {
            case .location(usage: .always):
                pendingCompletions.append(completion)
                locationManager.requestAlwaysAuthorization()
            case .location(usage: .whenInUse):
                pendingCompletions.append(completion)
                locationManager.requestWhenInUseAuthorization()
            default:
                fatalError("Incorrect permission type: \(permission)")
        }
#else
        fatalError("Location usage cannot be 'always' on this platform.")
#endif
    }

    // MARK: Location Manager delegate

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
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
                    fatalError("Location adapter has wrong type of permission")
                }
            case .authorizedWhenInUse:
                if case let .location(usage) = permission {
                    return usage == .whenInUse ? .authorized : .denied
                } else {
                    fatalError("Location adapter has wrong type of permission")
                }
        }
    }
}

