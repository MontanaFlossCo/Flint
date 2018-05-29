//
//  FeatureConstraints.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A container for the definition a single Feature's constraints.
public struct DeclaredFeatureConstraints {
    /// All the platform constraints that were declared on the feature, including those not relevant to the
    /// current execution platform
    public let allDeclaredPlatforms: [Platform:PlatformConstraint]
    
    /// The set of preconditions that apply to the feature
    public let preconditions: Set<FeaturePreconditionConstraint>
    
    /// The set of permission that apply to the feature
    public let permissions: Set<SystemPermissionConstraint>
    
    /// - return: `true` if and only there are no constraints that currently apply.
    public let isEmpty: Bool
    
    public static let empty = DeclaredFeatureConstraints()
    
    public init(allDeclaredPlatforms: [Platform:PlatformConstraint],
                preconditions: Set<FeaturePreconditionConstraint>,
                permissions: Set<SystemPermissionConstraint>) {
        self.allDeclaredPlatforms = allDeclaredPlatforms
        self.preconditions = preconditions
        self.permissions = permissions
        isEmpty = preconditions.isEmpty && permissions.isEmpty
    }

    public init(_ allDeclaredPlatforms: [Platform:PlatformConstraint]) {
        self.allDeclaredPlatforms = allDeclaredPlatforms
        permissions = []
        preconditions = []
        isEmpty = preconditions.isEmpty
    }
    
    public init(_ preconditions: Set<FeaturePreconditionConstraint>) {
        self.preconditions = preconditions
        permissions = []
        allDeclaredPlatforms = [:]
        isEmpty = preconditions.isEmpty
    }
    
    public init(_ permissions: Set<SystemPermissionConstraint>) {
        preconditions = []
        self.permissions = permissions
        allDeclaredPlatforms = [:]
        isEmpty = permissions.isEmpty
    }
    
    public init() {
        allDeclaredPlatforms = [:]
        preconditions = []
        permissions = []
        isEmpty = true
    }
}
