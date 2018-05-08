//
//  PermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The interface for components that provide access to underlying system permissions.
public protocol SystemPermissionAdapter {
    /// The permission this adapter can verify and authorise
    var permission: SystemPermission { get }
    
    /// The current status of the permission
    var status: SystemPermissionStatus { get }
    
    /// The OS's usage description key required for this permission.
    /// Used to sanity check that all required Info.plist are set
    var usageDescriptionKey: String { get }

    /// When called must ask the OS to ask the user to grant the permission
    func requestAuthorisation(completion: @escaping (_ adapter: SystemPermissionAdapter, _ status: SystemPermissionStatus) -> Void) 
}
