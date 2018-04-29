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
    case health(/* ? */)
    case motionAndFitness
    case speechRecognition
    case location(/* always/wheninuse */)
    case bluetoothSharing
    case mediaLibrary
}

public protocol PermissionsRequired {
    static var requiredPermissions: Set<Permission> { get }
}

public extension PermissionsRequired {
    public static func permissionsFulfilled() -> Bool {
        return Flint.permissionChecker?.isAuthorised(for: requiredPermissions) ?? false
    }
    
    public static func permissionsUnfulfilled() -> Set<Permission> {
        return []
    }
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
}

protocol PermissionAdapter {
    var status: PermissionStatus { get }
    var usageDescriptionKey: String { get }

    func requestAuthorisation()
}

class CameraPermissionAdapter: PermissionAdapter {
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

    var usageDescriptionKey: String { return "NSCameraUsageDescription" }

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
    weak var delegate: PermissionAdapterDelegate?
    
    var usageDescriptionKey: String { return "NSPhotoLibraryUsageDescription" }

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

/// !!! TODO: Add sanity check for missing Info.plist usage descriptions?
public class DefaultPermissionChecker: PermissionChecker {
    private let permissionAdapters: [Permission:PermissionAdapter]
    
    public init() {
        var permissionAdapters: [Permission:PermissionAdapter] = [:]

#if canImport(AVFoundation)
        permissionAdapters[.camera] = CameraPermissionAdapter()
#endif
#if canImport(Photos)
        permissionAdapters[.photos] = PhotosPermissionAdapter()
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
}
