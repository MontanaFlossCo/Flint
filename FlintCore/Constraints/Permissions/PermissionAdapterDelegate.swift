//
//  PermissionAdapterDelegate.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public protocol PermissionAdapterDelegate: AnyObject {
    func permissionStatusDidChange(sender: PermissionAdapter)
}
