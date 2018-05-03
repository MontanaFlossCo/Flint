//
//  PermissionAdapterDelegate.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The delegate interface for code that monitors changes to a system permission
public protocol SystemPermissionAdapterDelegate: AnyObject {
    func permissionStatusDidChange(sender: SystemPermissionAdapter)
}
