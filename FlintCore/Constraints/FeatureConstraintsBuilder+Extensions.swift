//
//  FeatureConstraintsBuilder+Extensions.swift
//  FlintCore
//
//  Created by Marc Palmer on 14/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Syntactic sugar
public extension FeatureConstraintsBuilder {
    /// Call to declare a list of permissions that your feature requires.
    public func permissions(_ requirements: SystemPermissionConstraint...) {
        for requirement in requirements {
            self.permission(requirement)
        }
    }

    /// Call to declare a list of purchase requiremnets that your feature gase
    public func purchases(_ requirements: PurchaseRequirement...) {
        for requirement in requirements {
            self.purchase(requirement)
        }
    }
}

/// Platform versions
public extension FeatureConstraintsBuilder {
    
    /// Set this to the minimum iOS version your feature requires
    public var iOS: PlatformVersionConstraint {
        get {
            flintUsageError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .iOS, version: newValue))
        }
    }

    /// Set this to the minimum iOS version your feature requires, if it only supports iOS and all other platforms
    /// should be set to `.unsupported`
    public var iOSOnly: PlatformVersionConstraint {
        get {
            flintUsageError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .macOS, version: .unsupported))
            self.platform(.init(platform: .tvOS, version: .unsupported))
            self.platform(.init(platform: .watchOS, version: .unsupported))
            self.platform(.init(platform: .iOS, version: newValue))
        }
    }

    /// Set this to the minimum watchOS version your feature requires
    public var watchOS: PlatformVersionConstraint {
        get {
            flintUsageError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .watchOS, version: newValue))
        }
    }

    /// Set this to the minimum watchOS version your feature requires, if it only supports watchOS and all other platforms
    /// should be set to `.unsupported`
    public var watchOSOnly: PlatformVersionConstraint {
        get {
            flintUsageError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .macOS, version: .unsupported))
            self.platform(.init(platform: .tvOS, version: .unsupported))
            self.platform(.init(platform: .watchOS, version: newValue))
            self.platform(.init(platform: .iOS, version: .unsupported))
        }
    }

    /// Set this to the minimum tvOS version your feature requires
    public var tvOS: PlatformVersionConstraint {
        get {
            flintUsageError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .tvOS, version: newValue))
        }
    }

    /// Set this to the minimum tvOS version your feature requires, if it only supports tvOS and all other platforms
    /// should be set to `.unsupported`
    public var tvOSOnly: PlatformVersionConstraint {
        get {
            flintUsageError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .macOS, version: .unsupported))
            self.platform(.init(platform: .tvOS, version: newValue))
            self.platform(.init(platform: .watchOS, version: .unsupported))
            self.platform(.init(platform: .iOS, version: .unsupported))
        }
    }

    /// Set this to the minimum macOS version your feature requires
    public var macOS: PlatformVersionConstraint {
        get {
            flintUsageError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .macOS, version: newValue))
        }
    }

    /// Set this to the minimum macOS version your feature requires, if it only supports macOS and all other platforms
    /// should be set to `.unsupported`
    public var macOSOnly: PlatformVersionConstraint {
        get {
            flintUsageError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .macOS, version: newValue))
            self.platform(.init(platform: .tvOS, version: .unsupported))
            self.platform(.init(platform: .watchOS, version: .unsupported))
            self.platform(.init(platform: .iOS, version: .unsupported))
        }
    }

}
