//
//  FeaturePrecondition.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public enum FeaturePrecondition: Hashable, Equatable {
    case platform(id: Platform, version: PlatformVersionConstraint)
    case userToggled(defaultValue: Bool)
    case runtimeEnabled
    case purchase(requirement: PurchaseRequirement)
}

