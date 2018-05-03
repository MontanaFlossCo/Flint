//
//  PlatformConstraint.swift
//  FlintCore
//
//  Created by Marc Palmer on 03/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public struct PlatformConstraint: Hashable, CustomStringConvertible {
    public let platform: Platform
    public let version: PlatformVersionConstraint
    
    public var description: String {
        return "\(platform) \(version)"
    }
}
