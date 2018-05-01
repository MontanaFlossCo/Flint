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
    let isEmpty: Bool
    
    public init(preconditions: Set<FeaturePrecondition>) {
        self.preconditions = preconditions
        isEmpty = preconditions.isEmpty
    }
}

