//
//  DefaultFeatureConstraintsBuilder.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public class DefaultFeatureConstraintsBuilder: FeatureConstraintsBuilder {
    private var preconditions: Set<FeaturePrecondition> = []
    private var permissions: Set<SystemPermission> = []

    public func build(_ block: (FeatureConstraintsBuilder) -> ()) -> FeatureConstraints {
        block(self)
        
        // !!! TODO: Sanity checks
        // 1. Veryify there aren't conflicting platform requirements for the same platform ID i.e. iOS 9 and iOS .any
        
        
        return FeatureConstraints(preconditions: preconditions, permissions: permissions)
    }
    
    public func precondition(_ requirement: FeaturePrecondition) {
        preconditions.insert(requirement)
    }

    public func permission(_ permission: SystemPermission) {
        permissions.insert(permission)
    }

}
