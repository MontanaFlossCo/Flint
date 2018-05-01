//
//  PermissionAdapter.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public protocol PermissionAdapter {
    var permission: SystemPermission { get }
    var status: PermissionStatus { get }
    var usageDescriptionKey: String { get }

    func requestAuthorisation()
}
