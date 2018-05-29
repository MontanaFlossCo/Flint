//
//  FeatureConstraintsEvaluationResult.swift
//  FlintCore
//
//  Created by Marc Palmer on 03/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public struct FeatureConstraintResult<T>: Hashable where T: FeatureConstraint {
    public let isActive: Bool
    public let isFulfilled: Bool?
    public let constraint: T
    
    public init(constraint: T, isActive: Bool, isFulfilled: Bool?) {
        self.isActive = isActive
        self.constraint = constraint
        self.isFulfilled = isFulfilled
    }
    
    public var hashValue: Int {
        return isActive.hashValue ^ (isFulfilled ?? false).hashValue ^ constraint.hashValue
    }

    public static func ==(lhs: FeatureConstraintResult<T>, rhs: FeatureConstraintResult<T>) -> Bool {
        return lhs.isActive == rhs.isActive &&
            lhs.isFulfilled == rhs.isFulfilled &&
            lhs.constraint == rhs.constraint
    }
}

/// A protocol that lets us get at basic information about any kind of constraint enum
public protocol FeatureConstraint: Hashable {
    var name: String { get }
    var parametersDescription: String { get }
}

extension SystemPermissionConstraint: FeatureConstraint {
    public var name: String { return String(describing: self) }
    public var parametersDescription: String {
        switch self {
            case .camera: return ""
            case .location(let usage): return "usage \(usage)"
            case .photos: return ""
        }
    }
}
extension FeaturePreconditionConstraint: FeatureConstraint {
    public var name: String { return String(describing: self) }
    public var parametersDescription: String {
        switch self {
            case .purchase(let requirement): return "requirement: \(requirement)"
            case .runtimeEnabled: return ""
            case .userToggled(let defaultValue): return "defaultValue: \(defaultValue)"
        }
    }
}
extension PlatformConstraint: FeatureConstraint {
    public var name: String { return String(describing: self) }
    public var parametersDescription: String {
        return self.version.description
    }
}

public protocol FeatureConstraintEvaluationResults {
    associatedtype ConstraintType: FeatureConstraint
    
    var all: Set<FeatureConstraintResult<ConstraintType>> { get }
    var satisfied: Set<FeatureConstraintResult<ConstraintType>> { get }
    var unsatisfied: Set<FeatureConstraintResult<ConstraintType>> { get }
    var unknown: Set<FeatureConstraintResult<ConstraintType>> { get }
}

public class DefaultFeatureConstraintEvaluationResults<ConstraintType>: FeatureConstraintEvaluationResults where ConstraintType: FeatureConstraint {
    public let all: Set<FeatureConstraintResult<ConstraintType>>

    public lazy var satisfied: Set<FeatureConstraintResult<ConstraintType>> = {
        return all.filter { $0.isActive && $0.isFulfilled == true }
    }()

    public lazy var unsatisfied: Set<FeatureConstraintResult<ConstraintType>> = {
        return all.filter { $0.isActive && $0.isFulfilled == false }
    }()

    public lazy var unknown: Set<FeatureConstraintResult<ConstraintType>> = {
        return all.filter { $0.isActive && $0.isFulfilled == nil }
    }()
    
    public init(_ results: Set<FeatureConstraintResult<ConstraintType>>) {
        self.all = results
    }

    public init(_ array: [FeatureConstraintResult<ConstraintType>]) {
        self.all = Set(array)
    }
}

/// The container for constraint evaluation results.
///
/// Use this to examine all the constraints on the feature and whether they are active and/or fulfilled.
public struct FeatureConstraintsEvaluation {
    public let permissions: DefaultFeatureConstraintEvaluationResults<SystemPermissionConstraint>
    public let preconditions: DefaultFeatureConstraintEvaluationResults<FeaturePreconditionConstraint>
    public let platforms: DefaultFeatureConstraintEvaluationResults<PlatformConstraint>

    public var hasUnsatisfiedConstraints: Bool {
        return permissions.unsatisfied.count > 0 || preconditions.unsatisfied.count > 0 || platforms.unsatisfied.count > 0
    }
    
    public var hasUnknownConstraints: Bool {
        return permissions.unknown.count > 0 || preconditions.unknown.count > 0 || platforms.unknown.count > 0
    }
    
    init(permissions: Set<FeatureConstraintResult<SystemPermissionConstraint>>,
         preconditions: Set<FeatureConstraintResult<FeaturePreconditionConstraint>>,
         platforms: Set<FeatureConstraintResult<PlatformConstraint>>) {
        self.permissions = DefaultFeatureConstraintEvaluationResults(permissions)
        self.preconditions = DefaultFeatureConstraintEvaluationResults(preconditions)
        self.platforms = DefaultFeatureConstraintEvaluationResults(platforms)
    }

    init(permissions: Set<FeatureConstraintResult<SystemPermissionConstraint>>) {
        self.permissions = DefaultFeatureConstraintEvaluationResults(permissions)
        self.preconditions = DefaultFeatureConstraintEvaluationResults([])
        self.platforms = DefaultFeatureConstraintEvaluationResults([])
    }

    init(preconditions: Set<FeatureConstraintResult<FeaturePreconditionConstraint>>) {
        self.permissions = DefaultFeatureConstraintEvaluationResults([])
        self.preconditions = DefaultFeatureConstraintEvaluationResults(preconditions)
        self.platforms = DefaultFeatureConstraintEvaluationResults([])
    }

    init(platforms: Set<FeatureConstraintResult<PlatformConstraint>>) {
        self.permissions = DefaultFeatureConstraintEvaluationResults([])
        self.preconditions = DefaultFeatureConstraintEvaluationResults([])
        self.platforms = DefaultFeatureConstraintEvaluationResults(platforms)
    }
}
