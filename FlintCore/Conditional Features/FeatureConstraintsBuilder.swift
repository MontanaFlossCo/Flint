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
    case runtimeEnabled(defaultValue: Bool)
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

    public func build(block: (FeatureConstraintsBuilder) -> ()) -> FeatureConstraints {
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
    func isFulfilled(_ precondition: FeaturePrecondition, for feature: ConditionalFeatureDefinition.Type) -> Bool
}

public class PlatformPreconditionEvaluator: FeaturePreconditionEvaluator {
    public func isFulfilled(_ precondition: FeaturePrecondition, for feature: ConditionalFeatureDefinition.Type) -> Bool {
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
    public func isFulfilled(_ precondition: FeaturePrecondition, for feature: ConditionalFeatureDefinition.Type) -> Bool {
        guard case let .purchase(requirement) = precondition else {
            fatalError("Incorrect precondition type '\(precondition)' passed to purchase evaluator")
        }

        return false
    }
}


public class RuntimeTogglePreconditionEvaluator: FeaturePreconditionEvaluator {
    public func isFulfilled(_ precondition: FeaturePrecondition, for feature: ConditionalFeatureDefinition.Type) -> Bool {
        guard case let .runtimeEnabled(defaultValue) = precondition else {
            fatalError("Incorrect precondition type '\(precondition)' passed to runtime evaluator")
        }

        return false
    }
}


public class UserTogglePreconditionEvaluator: FeaturePreconditionEvaluator {
    public func isFulfilled(_ precondition: FeaturePrecondition, for feature: ConditionalFeatureDefinition.Type) -> Bool {
        guard case let .userToggled(defaultValue) = precondition else {
            fatalError("Incorrect precondition type '\(precondition)' passed to user toggle evaluator")
        }
        
        return false
    }
}



public protocol ConstraintsEvaluator {
    func set(constraints: FeatureConstraints, for feature: ConditionalFeatureDefinition.Type)
    
    func evaluate(for feature: ConditionalFeatureDefinition.Type) -> (satisfied: FeatureConstraints, unsatisfied: FeatureConstraints)?
}

public class DefaultConstraintsEvaluator {
    var constraintsByFeature: [FeaturePath:FeatureConstraints] = [:]
    var platformEvaluator: FeaturePreconditionEvaluator = PlatformPreconditionEvaluator()
    var purchaseEvaluator: FeaturePreconditionEvaluator = PurchasePreconditionEvaluator()
    var runtimeEvaluator: FeaturePreconditionEvaluator = RuntimeTogglePreconditionEvaluator()
    var userToggleEvaluator: FeaturePreconditionEvaluator = UserTogglePreconditionEvaluator()

    func set(constraints: FeatureConstraints, for feature: ConditionalFeatureDefinition.Type) {
        constraintsByFeature[feature.identifier] = constraints
    }

    func evaluate(for feature: ConditionalFeatureDefinition.Type) -> (satisfied: FeatureConstraints, unsatisfied: FeatureConstraints)? {
        guard let constraints = constraintsByFeature[feature.identifier] else {
            return nil
        }
        
        var satisfiedPreconditions: Set<FeaturePrecondition> = []
        var unsatisfiedPreconditions: Set<FeaturePrecondition> = []
    
        for precondition in constraints.preconditions {
            let evaluator: FeaturePreconditionEvaluator
            
            switch precondition {
                case .platform(_, _):
                    evaluator = platformEvaluator
                case .purchase(_):
                    evaluator = purchaseEvaluator
                case .runtimeEnabled(_):
                    evaluator = runtimeEvaluator
                case .userToggled(_):
                    evaluator = userToggleEvaluator
            }
            
            if evaluator.isFulfilled(precondition, for: feature) {
                satisfiedPreconditions.insert(precondition)
            } else {
                unsatisfiedPreconditions.insert(precondition)
            }
        }
        
        return (satisfied: FeatureConstraints(preconditions: satisfiedPreconditions),
                unsatisfied: FeatureConstraints(preconditions: unsatisfiedPreconditions))
    }
}
