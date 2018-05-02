//
//  FeatureConstraintsBuilder.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public protocol FeatureConstraintsBuilder: AnyObject {
    func precondition(_ requirement: FeaturePrecondition)

    func permission(_ permission: SystemPermission)
}

public extension FeatureConstraintsBuilder {
    public func preconditions(_ requirements: FeaturePrecondition...) {
        for requirement in requirements {
            self.precondition(requirement)
        }
    }

    public func permissions(_ requirements: SystemPermission...) {
        for requirement in requirements {
            self.permission(requirement)
        }
    }
    
    public var iOS: PlatformVersionConstraint {
        get {
            fatalError("Not supported, you can only assign in this DSL")
        }
        set {
            self.precondition(.platform(id: .iOS, version: newValue))
        }
    }

    public var watchOS: PlatformVersionConstraint {
        get {
            fatalError("Not supported, you can only assign in this DSL")
        }
        set {
            self.precondition(.platform(id: .watchOS, version: newValue))
        }
    }

    public var tvOS: PlatformVersionConstraint {
        get {
            fatalError("Not supported, you can only assign in this DSL")
        }
        set {
            self.precondition(.platform(id: .tvOS, version: newValue))
        }
    }

    public var macOS: PlatformVersionConstraint {
        get {
            fatalError("Not supported, you can only assign in this DSL")
        }
        set {
            self.precondition(.platform(id: .macOS, version: newValue))
        }
    }
}
