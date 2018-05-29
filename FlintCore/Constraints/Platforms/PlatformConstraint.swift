//
//  PlatformConstraint.swift
//  FlintCore
//
//  Created by Marc Palmer on 03/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The struct used to define a single platform and version constraint.
public struct PlatformConstraint: Hashable, CustomStringConvertible {
    public let platform: Platform
    public let version: PlatformVersionConstraint
    
    public var description: String {
        return "\(platform) \(version)"
    }
}

extension PlatformConstraint: FeatureConstraint {
    public var name: String { return String(describing: self) }
    public var parametersDescription: String {
        return self.version.description
    }
}
