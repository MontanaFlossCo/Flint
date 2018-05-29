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
    private var userToggledPrecondition: FeaturePreconditionConstraint?
    private var runtimeEnabledPrecondition: FeaturePreconditionConstraint?
    private var purchasePreconditions: Set<FeaturePreconditionConstraint> = []
    private var permissions: Set<SystemPermissionConstraint> = []

    /// Call to build the constraints from the function passed in and return the structure
    /// with their definitions
    public func build(_ block: (FeatureConstraintsBuilder) -> ()) -> DeclaredFeatureConstraints {
        for platform in Platform.all {
            self.platform(PlatformConstraint(platform: platform, version: .any))
        }

        block(self)
        
        var preconditions: Set<FeaturePreconditionConstraint> = purchasePreconditions
        if let userToggledPrecondition = userToggledPrecondition {
            preconditions.insert(userToggledPrecondition)
        }
        if let runtimeEnabledPrecondition = runtimeEnabledPrecondition {
            preconditions.insert(runtimeEnabledPrecondition)
        }

        return DeclaredFeatureConstraints(allDeclaredPlatforms: platformCompatibility,
                                  preconditions: preconditions,
                                  permissions: permissions)
    }
    
    public func platform(_ requirement: PlatformConstraint) {
        platformCompatibility[requirement.platform] = requirement
    }

    public func runtimeEnabled() {
        runtimeEnabledPrecondition = FeaturePreconditionConstraint.runtimeEnabled
    }

    public func purchase(_ requirement: PurchaseRequirement) {
        purchasePreconditions.insert(.purchase(requirement: requirement))
    }

    public func userToggled(defaultValue: Bool) {
        userToggledPrecondition = FeaturePreconditionConstraint.userToggled(defaultValue: defaultValue)
    }

    public func permission(_ permission: SystemPermissionConstraint) {
        permissions.insert(permission)
    }

}
