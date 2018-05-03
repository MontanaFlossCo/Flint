//
//  FeaturePrecondition.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public enum FeaturePrecondition: Hashable, CustomStringConvertible {
    case userToggled(defaultValue: Bool)
    case runtimeEnabled
    case purchase(requirement: PurchaseRequirement)
    
    public var description: String {
        switch self {
            case .userToggled(let defaultValue): return "User toggled (default: \(defaultValue))"
            case .runtimeEnabled: return "Runtime enabled"
            case .purchase(let requirement): return "Purchase \(requirement.description)"
        }
    }
}
