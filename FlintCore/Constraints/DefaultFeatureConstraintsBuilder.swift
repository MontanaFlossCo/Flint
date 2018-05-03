//
//  DefaultFeatureConstraintsBuilder.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The standard implementation of the constraints builder, providing the basic
/// DSL functions required.
///
/// - see: `FeatureConstraintsBuilder` for the syntactic sugar applied to all implementations via extensions
public class DefaultFeatureConstraintsBuilder: FeatureConstraintsBuilder {
    private var platformCompatibility: [Platform:PlatformConstraint] = [:]
    private var preconditions: Set<FeaturePrecondition> = []
    private var permissions: Set<SystemPermission> = []

    /// Call to build the constraints from the function passed in and return the structure
    /// with their definitions
    public func build(_ block: (FeatureConstraintsBuilder) -> ()) -> FeatureConstraints {
        for platform in Platform.all {
            self.platform(PlatformConstraint(platform: platform, version: .any))
        }

        block(self)
        
        return FeatureConstraints(allDeclaredPlatforms: platformCompatibility,
                                  preconditions: preconditions,
                                  permissions: permissions)
    }
    
    public func platform(_ requirement: PlatformConstraint) {
        platformCompatibility[requirement.platform] = requirement
    }

    public func precondition(_ requirement: FeaturePrecondition) {
        preconditions.insert(requirement)
    }

    public func permission(_ permission: SystemPermission) {
        permissions.insert(permission)
    }

}
