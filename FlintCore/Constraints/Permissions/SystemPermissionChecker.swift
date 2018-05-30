//
//  PermissionChecker.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public protocol SystemPermissionCheckerDelegate: AnyObject {
    func permissionStatusDidChange(_ permission: SystemPermissionConstraint)
}

/// The interface for the component that will check that required permissions are granted.
///
/// Implementations must be safe to call from any thread.
///
/// - see: `DefaultPermissionChecker`
public protocol SystemPermissionChecker {
    var delegate: SystemPermissionCheckerDelegate? { get set }
    
    /// Must return `true` only if all the permissions are authorised
    func isAuthorised(for permissions: Set<SystemPermissionConstraint>) -> Bool

    /// Must return the status of the permission.
    func status(of permission: SystemPermissionConstraint) -> SystemPermissionStatus

    /// Must ask the user to grant the given permission
    func requestAuthorization(for permission: SystemPermissionConstraint, completion: @escaping (_ permission: SystemPermissionConstraint, _ status: SystemPermissionStatus) -> Void)
}

