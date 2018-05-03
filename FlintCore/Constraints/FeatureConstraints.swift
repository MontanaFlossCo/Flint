//
//  FeatureConstraints.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public struct FeatureConstraints  {
    let allDeclaredPlatforms: [Platform:PlatformConstraint]
    let currentPlatforms: [Platform:PlatformConstraint]
    let preconditions: Set<FeaturePrecondition>
    let permissions: Set<SystemPermission>
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
