//
//  Permissions.swift
//  FlintCore
//
//  Created by Marc Palmer on 28/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(Photos)
import Photos
#endif

public enum Permission: Hashable, Equatable {
    case camera
    case photos
    case contacts
    case calendars
    case reminders
    case homeKit
    case health
    case motionAndFitness
    case speechRecognition
    case location(usage: LocationUsage)
    case bluetoothSharing
    case mediaLibrary
}

public enum PermissionStatus {
    case unknown
    case authorized
    case denied
    case restricted
    case unsupported
}

public protocol PermissionChecker {
    func isAuthorised(for permissions: Set<Permission>) -> Bool

    func status(of permission: Permission) -> PermissionStatus

    func requestAuthorization(for permission: Permission)
}

protocol PermissionAdapter {
    var permission: Permission { get }
    var status: PermissionStatus { get }
    var usageDescriptionKey: String { get }

    func requestAuthorisation()
}

class CameraPermissionAdapter: PermissionAdapter {
    let permission: Permission = .camera
    let usageDescriptionKey: String = "NSCameraUsageDescription"

    var status: PermissionStatus {
#if canImport(AVFoundation)
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: return .authorized
            case .denied: return .denied
            case .notDetermined: return .unknown
            case .restricted: return .restricted
        }
#else
        return .unsupported
#endif
    }

    func requestAuthorisation() {
#if canImport(AVFoundation)
        guard status == .unknown else {
            return
        }
        
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                //access granted
            } else {

            }
        }
#endif
    }
}

protocol PermissionAdapterDelegate: AnyObject {
    func permissionStatusDidChange(sender: PermissionAdapter)
}

class PhotosPermissionAdapter: PermissionAdapter {
    let permission: Permission = .photos
    let usageDescriptionKey: String = "NSPhotoLibraryUsageDescription"

    weak var delegate: PermissionAdapterDelegate?
    
    var status: PermissionStatus {
#if canImport(Photos)
        switch PHPhotoLibrary.authorizationStatus() {
            case .authorized: return .authorized
            case .denied: return .denied
            case .notDetermined: return .unknown
            case .restricted: return .restricted
        }
#else
        return .unsupported
#endif
    }
    
    func requestAuthorisation() {
#if canImport(Photos)
        guard status == .unknown else {
            return
        }
        
        PHPhotoLibrary.requestAuthorization({status in
            if status != .notDetermined {
                self.delegate?.permissionStatusDidChange(sender: self)
            }
        })
#endif
    }
}

public enum LocationUsage {
    case always
    case whenInUse
}

@objc class LocationPermissionAdapter: NSObject, PermissionAdapter, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    
    let permission: Permission
    let usageDescriptionKey: String = "NSLocationWhenInUseUsageDescription"

    weak var delegate: PermissionAdapterDelegate?
    
    var status: PermissionStatus {
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

/// !!! TODO: Add sanity check for missing Info.plist usage descriptions?
public class DefaultPermissionChecker: PermissionChecker, CustomDebugStringConvertible {
    private let permissionAdapters: [Permission:PermissionAdapter]
    
    public init() {
        var permissionAdapters: [Permission:PermissionAdapter] = [:]

        func _add(_ adapter: PermissionAdapter) {
            permissionAdapters[adapter.permission] = adapter
        }
        
#if canImport(AVFoundation)
        _add(CameraPermissionAdapter())
#endif
#if canImport(Photos)
        _add(PhotosPermissionAdapter())
#endif
#if canImport(CoreLocation)
        _add(LocationPermissionAdapter(usage: .whenInUse))
        _add(LocationPermissionAdapter(usage: .always))
#endif

        self.permissionAdapters = permissionAdapters
    }

    public func isAuthorised(for permissions: Set<Permission>) -> Bool {
        var result = false
        for permission in permissions {
            if status(of: permission) != .authorized {
                result = false
                break
            } else {
                result = true
            }
        }
        return result
    }
    
    public func status(of permission: Permission) -> PermissionStatus {
        guard let adapter = permissionAdapters[permission] else {
            fatalError("No permission adapter for \(permission)")
        }
        return adapter.status
    }
    
    public func requestAuthorization(for permission: Permission) {
        guard let adapter = permissionAdapters[permission] else {
            fatalError("No permission adapter for \(permission)")
        }
        adapter.requestAuthorisation()
    }

    public var debugDescription: String {
        let results = permissionAdapters.values.map { adapter in
            return "\(adapter.permission): \(adapter.status)"
        }
        return "Current permission statuses:\n\(results.joined(separator: "\n"))"
    }
}
