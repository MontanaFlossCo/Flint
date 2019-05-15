//
//  DefaultPermissionChecker.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public enum ContactsEntity {
    case contacts
}

/// The implementation of the system permission checker.
///
/// This registers and verifies the approprite adapters and uses them to check the status
/// of all the permissions required by a feature.
///
/// !!! TODO: Add sanity check for missing Info.plist usage descriptions?
public class DefaultPermissionChecker: SystemPermissionChecker, CustomDebugStringConvertible {
    /// - note: Access only from the accessQueue
    private var permissionAdapters: [SystemPermissionConstraint:SystemPermissionAdapter] = [:]
    
    public weak var delegate: SystemPermissionCheckerDelegate?
    
    private var accessQueue = DispatchQueue(label: "tools.flint.permission-checker")
    
    public init() {
    }
    
    /// - note: Call only from the access queue
    private func add(_ adapters: [SystemPermissionAdapter]) {
        for adapter in adapters {
            permissionAdapters[adapter.permission] = adapter
        }
    }

    /// Get the correct adapter for a given permission, lazily creating it if it has not been requested
    /// previously. This allows us to avoid bootstrapping a bunch of SDK APIs e.g. CoreLocation if the permission
    /// is never used.
    private func getAdapter(for permission: SystemPermissionConstraint) -> SystemPermissionAdapter? {
        return accessQueue.sync {
            // Fast-path with existing adapters
            if let result = permissionAdapters[permission] {
                return result
            }
            
            // Lazily create the required adapter, to avoid e.g. creating a location manager when it is not needed
            let adapterType: SystemPermissionAdapter.Type?
            switch permission {
                case .camera:
                    adapterType = CameraPermissionAdapter.self
                case .microphone:
                    adapterType = MicrophonePermissionAdapter.self
                case .location:
                    adapterType = LocationPermissionAdapter.self
                case .contacts:
                    adapterType = ContactsPermissionAdapter.self
                case .photos:
                    adapterType = PhotosPermissionAdapter.self
                case .calendarEvents:
                    adapterType = EventKitPermissionAdapter.self
                case .reminders:
                    adapterType = EventKitPermissionAdapter.self
                case .motion:
                    adapterType = MotionPermissionAdapter.self
                case .speechRecognition:
                    adapterType = SpeechRecognitionPermissionAdapter.self
                case .siriKit:
                    adapterType = SiriKitPermissionAdapter.self
            }

            if let adapter = adapterType {
                if adapter.isSupported {
                    // We probably need to also verify there is actual camera hardware, e.g. WatchOS
                    add(adapter.createAdapters(for: permission))
                } else {
                    FlintInternal.logger?.warning("Permission \"\(permission)\" is not supported. Either the target platform does not implement it, or your target is not linking the framework required.")
                }
            }

            // Return the one appropriate for the request, now we have it created (if possible)
            return permissionAdapters[permission]
        }
    }

    public func isAuthorised(for permissions: Set<SystemPermissionConstraint>) -> Bool {
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
    
    public func status(of permission: SystemPermissionConstraint) -> SystemPermissionStatus {
        guard let adapter = getAdapter(for: permission) else {
            FlintInternal.logger?.warning("Cannot get status for permission \(permission), there is no adapter for it")
            return .unsupported
        }
        return adapter.status
    }
    
    public func requestAuthorization(for permission: SystemPermissionConstraint,
                                     completion: @escaping (_ permission: SystemPermissionConstraint, _ status: SystemPermissionStatus) -> Void) {
        guard let adapter = getAdapter(for: permission) else {
            flintBug("No permission adapter for \(permission)")
        }

        FlintInternal.logger?.debug("Permission checker requesting authorization for: \(permission)")

        adapter.requestAuthorisation { adapter, status in
            FlintInternal.logger?.debug("Permission checker authorization request for: \(permission) resulted in \(status)")
            completion(adapter.permission, status)
            // Tell our delegate that things were updated - caches will need to be invalidated etc.
            self.delegate?.permissionStatusDidChange(adapter.permission)
        }
    }

    public var debugDescription: String {
        let adapters = accessQueue.sync { permissionAdapters }
        let results = adapters.values.map { adapter in
            return "\(adapter.permission): \(adapter.status)"
        }
        return "Current permission statuses:\n\(results.joined(separator: "\n"))"
    }
}
