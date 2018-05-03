//
//  PermissionChecker.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The interface for the component that will check that required permissions are granted.
///
/// - see: `DefaultPermissionChecker`
public protocol SystemPermissionChecker {
    /// Must return `true` only if all the permissions are authorised
    func isAuthorised(for permissions: Set<SystemPermission>) -> Bool

    /// Must return the status of the permission
    func status(of permission: SystemPermission) -> SystemPermissionStatus

    /// Must ask the user to grant the given permission
    func requestAuthorization(for permission: SystemPermission)
}

