//
//  FeatureConstraints.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public struct FeatureConstraints  {
    let preconditions: Set<FeaturePrecondition>
    let permissions: Set<SystemPermission>
    let isEmpty: Bool
    
    public static let empty = FeatureConstraints()
    
    public init(preconditions: Set<FeaturePrecondition>, permissions: Set<SystemPermission>) {
        self.preconditions = preconditions
        self.permissions = permissions
        isEmpty = preconditions.isEmpty && permissions.isEmpty
    }

    public init(_ preconditions: Set<FeaturePrecondition>) {
        self.preconditions = preconditions
        permissions = []
        isEmpty = preconditions.isEmpty
    }
    
    public init(_ permissions: Set<SystemPermission>) {
        self.preconditions = []
        self.permissions = permissions
        isEmpty = permissions.isEmpty
    }
    
    public init() {
        preconditions = []
        permissions = []
        isEmpty = true
    }
}
