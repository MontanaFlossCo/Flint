//
//  PermissionChecker.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public protocol PermissionChecker {
    func isAuthorised(for permissions: Set<SystemPermission>) -> Bool

    func status(of permission: SystemPermission) -> PermissionStatus

    func requestAuthorization(for permission: SystemPermission)
}

