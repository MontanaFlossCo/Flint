//
//  FeatureConstraintsEvaluationResult.swift
//  FlintCore
//
//  Created by Marc Palmer on 03/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public struct FeatureConstraintDescription {
    let type: Any.Type
    let name: String
    
    init<T>(constraint: T) where T: FeatureConstraint {
    
    }
}

public protocol FeatureConstraintResult: Hashable {
    var isActive: Bool { get }
    var isFulfilled: Bool? { get }
    var constraint: FeatureConstraintDescription { get }
}

public struct AnyFeatureConstraintResult: Hashable {
    public let constraint: AnyFeatureConstraint
    public let isFulfilled: Bool?

    public var description: String {
        return _description()
    }
    
    private let _description: () -> String
    private let _equals: () -> String

    init<T>(constraint: T) where T: FeatureConstraint {
        _description = { return constraint.description }
    }
    
    public static func ==(lhs: AnyFeatureConstraintResult, rhs: AnyFeatureConstraintResult) -> Bool {
        return lhs.
    }
}

public protocol FeatureConstraint {
    var name: String { get }
    var parametersDescription: String { get }
}

extension SystemPermissionConstraint: FeatureConstraint { }
extension FeaturePreconditionConstraint: FeatureConstraint { }
extension PlatformConstraint: FeatureConstraint { }


/// The container for constraint evaluation results.
public struct FeatureConstraintsEvaluationResult {
    /// The information about all the constraints declared
    public let constraints: Set<AnyFeatureConstraintResult>

    init(constraints: Set<AnyFeatureConstraintResult>) {
        self.all = results
        self.satisfied = Set(results.filter({ result in
            return
        }))
        self.unsatisfied = unsatisfied
        self.unknown = unknown
    }

    init(satisfied: DeclaredFeatureConstraints) {
        self.all = satisfied
        self.satisfied = satisfied
        self.unsatisfied = DeclaredFeatureConstraints()
        self.unknown = DeclaredFeatureConstraints()
    }

    init(unsatisfied: DeclaredFeatureConstraints) {
        self.all = unsatisfied
        self.satisfied = DeclaredFeatureConstraints()
        self.unsatisfied = unsatisfied
        self.unknown = DeclaredFeatureConstraints()
    }

    init(unknown: DeclaredFeatureConstraints) {
        self.all = unknown
        self.satisfied = DeclaredFeatureConstraints()
        self.unsatisfied = DeclaredFeatureConstraints()
        self.unknown = unknown
    }

}
