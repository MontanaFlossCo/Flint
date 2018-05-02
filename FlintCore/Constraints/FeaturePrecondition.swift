//
//  FeaturePrecondition.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public enum FeaturePrecondition: Hashable, Equatable {
    case platform(id: Platform, version: PlatformVersionConstraint)
    case userToggled(defaultValue: Bool)
    case runtimeEnabled
    case purchase(requirement: PurchaseRequirement)
}

/// Syntactic sugar
public extension FeaturePrecondition {
    static func iOS(_ version: PlatformVersionConstraint) -> FeaturePrecondition {
        return .platform(id: .iOS, version: version)
    }

    static var iOS: FeaturePrecondition {
        return .platform(id: .iOS, version: .any)
    }

    static func macOS(_ version: PlatformVersionConstraint) -> FeaturePrecondition {
        return .platform(id: .macOS, version: version)
    }

    static var macOS: FeaturePrecondition {
        return .platform(id: .macOS, version: .any)
    }

    static func watchOS(_ version: PlatformVersionConstraint) -> FeaturePrecondition {
        return .platform(id: .watchOS, version: version)
    }

    static var watchOS: FeaturePrecondition {
        return .platform(id: .watchOS, version: .any)
    }

    static func tvOS(_ version: PlatformVersionConstraint) -> FeaturePrecondition {
        return .platform(id: .tvOS, version: version)
    }

    static var tvOS: FeaturePrecondition {
        return .platform(id: .tvOS, version: .any)
    }
}

