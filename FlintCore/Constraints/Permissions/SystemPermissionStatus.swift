//
//  PermissionStatus.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Permissions required by features can be in a variety of states, this
/// encapsulates those aacross all the different permission types
public enum SystemPermissionStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unsupported
}
