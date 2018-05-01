//
//  FeatureConstraintsBuilder.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public enum Platform: Hashable, Equatable {
    case iOS
    case watchOS
    case tvOS
    case macOS
}

extension OperatingSystemVersion: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = UInt
    
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(majorVersion: Int(value), minorVersion: 0, patchVersion: 0)
    }
}

extension OperatingSystemVersion: Hashable, Equatable {
    public static func ==(lhs: OperatingSystemVersion, rhs: OperatingSystemVersion) -> Bool {
        return lhs.majorVersion == rhs.majorVersion &&
            lhs.minorVersion == rhs.minorVersion &&
            lhs.patchVersion == rhs.minorVersion
    }
    
    public var hashValue: Int {
        return majorVersion * minorVersion * patchVersion
    }
}

public enum PlatformVersionConstraint: Hashable, Equatable {
    case any
    case atLeast(version: OperatingSystemVersion)
}

public enum FeaturePrecondition: Hashable, Equatable {
    case platform(id: Platform, version: PlatformVersionConstraint)
    case userToggled(defaultValue: Bool)
    case runtimeEnabled
    case purchase(requirement: PurchaseRequirement)
}

public protocol FeatureConstraintsBuilder {
    func precondition(_ requirement: FeaturePrecondition)
}

public struct FeatureConstraints  {
    let preconditions: Set<FeaturePrecondition>
    let isEmpty: Bool
    
    public init(preconditions: Set<FeaturePrecondition>) {
        self.preconditions = preconditions
        isEmpty = preconditions.isEmpty
    }
}

public class DefaultConstraintsBuilder: FeatureConstraintsBuilder {
    private var preconditions: Set<FeaturePrecondition> = []

    public func build(_ block: (FeatureConstraintsBuilder) -> ()) -> FeatureConstraints {
        block(self)
        return FeatureConstraints(preconditions: preconditions)
    }
    
    public func precondition(_ requirement: FeaturePrecondition) {
        preconditions.insert(requirement)
    }
}

public struct ConstraintsCollection {
    let preconditions: Set<FeaturePrecondition>
}

public protocol FeaturePreconditionEvaluator {
    func isFulfilled(_ precondition: FeaturePrecondition, for feature: ConditionalFeatureDefinition.Type) -> Bool?
}

public class PlatformPreconditionEvaluator: FeaturePreconditionEvaluator {
    public func isFulfilled(_ precondition: FeaturePrecondition, for feature: ConditionalFeatureDefinition.Type) -> Bool? {
        guard case let .platform(id, version) = precondition else {
            fatalError("Incorrect precondition type '\(precondition)' passed to platform evaluator")
        }
        switch (id, version) {
            case (.iOS, .any):
#if os(iOS)
                return true
#else
                return false
#endif
            case (.iOS, .atLeast(let version)):
#if os(iOS)
                return ProcessInfo.processInfo.isOperatingSystemAtLeast(version)
#else
                return false
#endif
            case (.watchOS, .any):
#if os(watchOS)
                return true
#else
                return false
#endif
            case (.watchOS, .atLeast(let version)):
#if os(watchOS)
                return ProcessInfo.processInfo.isOperatingSystemAtLeast(version)
#else
                return false
#endif
            case (.tvOS, .any):
#if os(tvOS)
                return true
#else
                return false
#endif
            case (.tvOS, .atLeast(let version)):
#if os(tvOS)
                return ProcessInfo.processInfo.isOperatingSystemAtLeast(version)
#else
                return false
#endif
            case (.macOS, .any):
#if os(macOS)
                return true
#else
                return false
#endif
            case (.macOS, .atLeast(let version)):
#if os(macOS)
                return ProcessInfo.processInfo.isOperatingSystemAtLeast(version)
#else
                return false
#endif
        }
    }
}

public class PurchasePreconditionEvaluator: FeaturePreconditionEvaluator {
    let purchaseTracker: PurchaseTracker
    
    public init(purchaseTracker: PurchaseTracker) {
        self.purchaseTracker = purchaseTracker
    }
    
    public func isFulfilled(_ precondition: FeaturePrecondition, for feature: ConditionalFeatureDefinition.Type) -> Bool? {
        guard case let .purchase(requirement) = precondition else {
            fatalError("Incorrect precondition type '\(precondition)' passed to purchase evaluator")
        }

        return requirement.isFulfilled(validator: purchaseTracker)
    }
}


public class RuntimeTogglePreconditionEvaluator: FeaturePreconditionEvaluator {
    public func isFulfilled(_ precondition: FeaturePrecondition, for feature: ConditionalFeatureDefinition.Type) -> Bool? {
        guard case .runtimeEnabled = precondition else {
            fatalError("Incorrect precondition type '\(precondition)' passed to runtime evaluator")
        }

        return feature.enabled
    }
}


public class UserTogglePreconditionEvaluator: FeaturePreconditionEvaluator {
    let userToggles: UserFeatureToggles
    
    public init(userToggles: UserFeatureToggles) {
        self.userToggles = userToggles
    }

    public func isFulfilled(_ precondition: FeaturePrecondition, for feature: ConditionalFeatureDefinition.Type) -> Bool? {
        guard case let .userToggled(defaultValue) = precondition else {
            fatalError("Incorrect precondition type '\(precondition)' passed to user toggle evaluator")
        }
        
        return userToggles.isEnabled(feature) ?? defaultValue
    }
}



public protocol ConstraintsEvaluator {
    func description(for feature: ConditionalFeatureDefinition.Type) -> String
    
    func set(constraints: FeatureConstraints, for feature: ConditionalFeatureDefinition.Type)

    func canCacheResult(for feature: ConditionalFeatureDefinition.Type) -> Bool
    
    func evaluate(for feature: ConditionalFeatureDefinition.Type) -> (satisfied: FeatureConstraints, unsatisfied: FeatureConstraints, unknown: FeatureConstraints)
}

public class DefaultConstraintsEvaluator: ConstraintsEvaluator {
    var constraintsByFeature: [FeaturePath:FeatureConstraints] = [:]
    var platformEvaluator: FeaturePreconditionEvaluator = PlatformPreconditionEvaluator()
    var purchaseEvaluator: FeaturePreconditionEvaluator?
    var runtimeEvaluator: FeaturePreconditionEvaluator = RuntimeTogglePreconditionEvaluator()
    var userToggleEvaluator: FeaturePreconditionEvaluator?

    public init(purchaseTracker: PurchaseTracker?, userToggles: UserFeatureToggles?) {
        if let purchaseTracker = purchaseTracker {
            purchaseEvaluator = PurchasePreconditionEvaluator(purchaseTracker: purchaseTracker)
        }
        if let userToggles = userToggles {
            userToggleEvaluator = UserTogglePreconditionEvaluator(userToggles: userToggles)
        }
    }
    
    public func description(for feature: ConditionalFeatureDefinition.Type) -> String {
        if let constraints = constraintsByFeature[feature.identifier] {
            return String(describing: constraints)
        } else {
            return "<none>"
        }
    }

    public func canCacheResult(for feature: ConditionalFeatureDefinition.Type) -> Bool {
        if let constraints = constraintsByFeature[feature.identifier] {
            // The runtime `enabled` flag can be toggled by the app, typically at startup and we don't want to have to force
            // the developer to invalidate everything else every time.
            return !constraints.preconditions.contains(.runtimeEnabled)
        } else {
            return true
        }
    }
    
    public func set(constraints: FeatureConstraints, for feature: ConditionalFeatureDefinition.Type) {
        constraintsByFeature[feature.identifier] = constraints
    }

    public func evaluate(for feature: ConditionalFeatureDefinition.Type) -> (satisfied: FeatureConstraints, unsatisfied: FeatureConstraints, unknown: FeatureConstraints) {
        var satisfiedPreconditions: Set<FeaturePrecondition> = []
        var unsatisfiedPreconditions: Set<FeaturePrecondition> = []
        var unknownPreconditions: Set<FeaturePrecondition> = []

        if let constraints = constraintsByFeature[feature.identifier] {
            for precondition in constraints.preconditions {
                let evaluator: FeaturePreconditionEvaluator
                
                switch precondition {
                    case .platform(_, _):
                        evaluator = platformEvaluator
                    case .purchase(_):
                        guard let purchaseEvaluator = purchaseEvaluator else {
                            fatalError("Feature '\(feature)' has a purchase precondition but there is no purchase evaluator")
                        }
                        evaluator = purchaseEvaluator
                    case .runtimeEnabled:
                        evaluator = runtimeEvaluator
                    case .userToggled(_):
                        guard let userToggleEvaluator = userToggleEvaluator else {
                            fatalError("Feature '\(feature)' has a user toggling precondition but there is no purchase evaluator")
                        }
                        evaluator = userToggleEvaluator
                }
                
                switch evaluator.isFulfilled(precondition, for: feature) {
                    case .some(true): satisfiedPreconditions.insert(precondition)
                    case .some(false): unsatisfiedPreconditions.insert(precondition)
                    case .none: unknownPreconditions.insert(precondition)
                }
            }
        }
        
        return (satisfied: FeatureConstraints(preconditions: satisfiedPreconditions),
                unsatisfied: FeatureConstraints(preconditions: unsatisfiedPreconditions),
                unknown: FeatureConstraints(preconditions: unsatisfiedPreconditions))
    }
}
