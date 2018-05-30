//
//  HomeKitPermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 30/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(HomeKit)
import HomeKit
#endif

/// HomeKit access permissions.
///
/// There's no way to request authorization other than calling an API. The only way to tell status
/// is likely getting an `Error` back from one of these, indicating authorisation failure.
///
/// The ugly duckling of auth APIs. 
///
/// Supports: iOS 8+, macOS ⛔️, watchOS 2+, tvOS 10+
class HomeKitPermissionAdapter: SystemPermissionAdapter {
    static var isSupported: Bool {
#if canImport(HomeKit)
        if #available(iOS 8, watchOS 2, tvOS 10, *) {
            return true
        } else {
            return false
        }
#else
        return false
#endif
    }
    
    static func createAdapters(for permission: SystemPermissionConstraint) -> [SystemPermissionAdapter] {
        return [HomeKitPermissionAdapter(permission: permission)]
    }
    
    let permission: SystemPermissionConstraint
    
    var status: SystemPermissionStatus {
        return .notDetermined
    }
    
    let usageDescriptionKey: String = "NSHomeKitUsageDescription"
    
    init(permission: SystemPermissionConstraint) {
        self.permission = permission
    }
    
    func requestAuthorisation(completion: @escaping (SystemPermissionAdapter, SystemPermissionStatus) -> Void) {
    }
}
