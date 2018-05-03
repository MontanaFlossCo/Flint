//
//  FeatureConstraints.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A container for the definition and results of evaluating a single Feature's constraints.
public struct FeatureConstraints  {
    /// All the platform constraints that were declared on the feature, including those not relevant to the
    /// current execution platform
    let allDeclaredPlatforms: [Platform:PlatformConstraint]
    
    /// The platform constraints that apply to the current OS only
    let currentPlatforms: [Platform:PlatformConstraint]
    
    /// The set of preconditions that apply to the feature
    let preconditions: Set<FeaturePrecondition>
    
    /// The set of permission that apply to the feature
    let permissions: Set<SystemPermission>
    
    /// - return: `true` if and only there are no constraints that currently apply.
    let isEmpty: Bool
    
    public static let empty = FeatureConstraints()
    
    public init(allDeclaredPlatforms: [Platform:PlatformConstraint],
                preconditions: Set<FeaturePrecondition>,
                permissions: Set<SystemPermission>) {
        self.allDeclaredPlatforms = allDeclaredPlatforms
        self.currentPlatforms = allDeclaredPlatforms.filter { $0.value.platform.isCurrentPlatform }
        self.preconditions = preconditions
        self.permissions = permissions
        isEmpty = currentPlatforms.isEmpty && preconditions.isEmpty && permissions.isEmpty
    }

    public init(_ allDeclaredPlatforms: [Platform:PlatformConstraint]) {
        self.allDeclaredPlatforms = allDeclaredPlatforms
        self.currentPlatforms = allDeclaredPlatforms.filter { $0.value.platform.isCurrentPlatform }
        permissions = []
        preconditions = []
        isEmpty = preconditions.isEmpty
    }
    
    public init(_ preconditions: Set<FeaturePrecondition>) {
        self.preconditions = preconditions
        permissions = []
        allDeclaredPlatforms = [:]
        currentPlatforms = [:]
        isEmpty = preconditions.isEmpty
    }
    
    public init(_ permissions: Set<SystemPermission>) {
        preconditions = []
        self.permissions = permissions
        allDeclaredPlatforms = [:]
        currentPlatforms = [:]
        isEmpty = permissions.isEmpty
    }
    
    public init() {
        allDeclaredPlatforms = [:]
        currentPlatforms = [:]
        preconditions = []
        permissions = []
        isEmpty = true
    }
}
