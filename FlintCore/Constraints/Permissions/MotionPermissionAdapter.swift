//
//  MotionPermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 31/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(CoreMotion)
import CoreMotion
#endif

/// Support: iOS 11+, macOS ⛔️, watchOS 4+, tvOS ⛔️
class MotionPermissionAdapter: SystemPermissionAdapter {
    static var isSupported: Bool {
#if canImport(CoreMotion)
        
        return CMMotionActivityManager.isActivityAvailable()
#else
        return false
#endif
        }
    
    static func createAdapters(for permission: SystemPermissionConstraint) -> [SystemPermissionAdapter] {
        return [MotionPermissionAdapter(permission: permission)]
    }
    
    let permission: SystemPermissionConstraint
    
    var status: SystemPermissionStatus {
#if canImport(CoreMotion)
        if #available(iOS 11, watchOS 4, *) {
            return authStatusToPermissionStatus(CMMotionActivityManager.authorizationStatus())
        } else {
            return .unsupported
        }
#else
        return .unsupported
#endif
        }
    
    let usageDescriptionKey: String = "NSMotionUsageDescription"

    private lazy var activityManager: CMMotionActivityManager = { CMMotionActivityManager() }()
    
    init(permission: SystemPermissionConstraint) {
        guard permission == .motion else {
            preconditionFailure("Cannot use MotionPermissionAdapter with: \(permission)")
        }
        self.permission = permission
    }
    
    func requestAuthorisation(completion: @escaping (SystemPermissionAdapter, SystemPermissionStatus) -> Void) {
        let start = Date().addingTimeInterval(-24*60*60)
        let end = Date()

#if canImport(CoreMotion)
        activityManager.queryActivityStarting(from: start, to: end, to: .main) { [weak self] (activity: [CMMotionActivity]?, error: Error?) in
            if let strongSelf = self {
                completion(strongSelf, strongSelf.status)
            }
        }
#else
        completion(self, .unsupported)
#endif
    }
    
#if canImport(CoreMotion)
    @available(iOS 11, watchOS 4, *)
    func authStatusToPermissionStatus(_ authStatus: CMAuthorizationStatus) -> SystemPermissionStatus {
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
