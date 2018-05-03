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
    
    let permission: SystemPermission
    let usageDescriptionKey: String = "NSLocationWhenInUseUsageDescription"

    weak var delegate: SystemPermissionAdapterDelegate?
    
    var status: SystemPermissionStatus {
        switch CLLocationManager.authorizationStatus() {
            case .denied: return .denied
            case .notDetermined: return .unknown
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
    
    public init(usage: LocationUsage) {
        switch usage {
            case .always: permission = .location(usage: .always)
            case .whenInUse: permission = .location(usage: .whenInUse)
        }
        super.init()
        locationManager.delegate = self
    }
    
    func requestAuthorisation() {
        guard status == .unknown else {
            return
        }
        
        guard case let .location(usage) = permission else {
            return
        }
        
        switch usage {
            case .always:
                locationManager.requestAlwaysAuthorization()
            case .whenInUse:
                locationManager.requestWhenInUseAuthorization()
        }
    }

    // MARK: Location Manager delegate

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status != .notDetermined {
            self.delegate?.permissionStatusDidChange(sender: self)
        }
    }
}

