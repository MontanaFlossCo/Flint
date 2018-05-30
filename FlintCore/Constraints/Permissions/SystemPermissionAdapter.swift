//
//  PermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The interface for components that provide access to underlying system permissions.
public protocol SystemPermissionAdapter: AnyObject {
    /// Must return `true` only if this permission is available on the current runtime platform and device.
    /// This is used by the permission checker to avoid instantiating adapters that are not relevant, and to avoid
    /// access to APIs that are not available on all devices. Without this the permission checker has to have all
    /// the #if os(xxx) checks, which is invasive
    static var isSupported: Bool { get }
    
    /// Called to create all the adapters supported by this type of permission.
    /// This is called to enable adapters that have multiple variants to create all the appropriate
    /// objects for the current platform.
    static func createAdapters() -> [SystemPermissionAdapter]

    /// The permission this adapter can verify and authorise
    var permission: SystemPermissionConstraint { get }
    
    /// The current status of the permission
    var status: SystemPermissionStatus { get }
    
    /// The OS's usage description key required for this permission.
    /// Used to sanity check that all required Info.plist are set
    var usageDescriptionKey: String { get }

    /// When called must ask the OS to ask the user to grant the permission
    func requestAuthorisation(completion: @escaping (_ adapter: SystemPermissionAdapter, _ status: SystemPermissionStatus) -> Void) 
}
