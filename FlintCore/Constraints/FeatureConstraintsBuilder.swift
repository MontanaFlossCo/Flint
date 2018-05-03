//
//  FeatureConstraintsBuilder.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public protocol FeatureConstraintsBuilder: AnyObject {
    func platform(_ requirement: PlatformConstraint)

    func precondition(_ requirement: FeaturePrecondition)

    func permission(_ permission: SystemPermission)
}

/// Syntactic sugar
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
            self.platform(.init(platform: .iOS, version: newValue))
        }
    }

    public var iOSOnly: PlatformVersionConstraint {
        get {
            fatalError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .macOS, version: .unsupported))
            self.platform(.init(platform: .tvOS, version: .unsupported))
            self.platform(.init(platform: .watchOS, version: .unsupported))
            self.platform(.init(platform: .iOS, version: newValue))
        }
    }

    public var watchOS: PlatformVersionConstraint {
        get {
            fatalError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .watchOS, version: newValue))
        }
    }

    public var watchOSOnly: PlatformVersionConstraint {
        get {
            fatalError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .macOS, version: .unsupported))
            self.platform(.init(platform: .tvOS, version: .unsupported))
            self.platform(.init(platform: .watchOS, version: newValue))
            self.platform(.init(platform: .iOS, version: .unsupported))
        }
    }

    public var tvOS: PlatformVersionConstraint {
        get {
            fatalError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .tvOS, version: newValue))
        }
    }

    public var tvOSOnly: PlatformVersionConstraint {
        get {
            fatalError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .macOS, version: .unsupported))
            self.platform(.init(platform: .tvOS, version: newValue))
            self.platform(.init(platform: .watchOS, version: .unsupported))
            self.platform(.init(platform: .iOS, version: .unsupported))
        }
    }

    public var macOS: PlatformVersionConstraint {
        get {
            fatalError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .macOS, version: newValue))
        }
    }

    public var macOSOnly: PlatformVersionConstraint {
        get {
            fatalError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .macOS, version: newValue))
            self.platform(.init(platform: .tvOS, version: .unsupported))
            self.platform(.init(platform: .watchOS, version: .unsupported))
            self.platform(.init(platform: .iOS, version: .unsupported))
        }
    }

}
