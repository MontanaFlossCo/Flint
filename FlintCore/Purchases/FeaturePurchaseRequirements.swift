//
//  FeaturePurchaseRequirements.swift
//  FlintCore
//
//  Created by Marc Palmer on 09/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This type provides information about the purchases required for a single conditional feature.
///
/// You can use this at runtime to establish which purchases you need to show to the user to enable them to unlock
/// a feature.
public struct FeaturePurchaseRequirements {
    /// The set of all purchases required that must be met for the feature to be available
    public let all: Set<PurchaseRequirement>

    /// The set of all purchases required that must be met for the feature to be available, which have not already been purchased.
    public let requiredToUnlock: Set<PurchaseRequirement>

    /// The set of all purchases that this feature requires, which have already been purchased
    public let purchased: Set<PurchaseRequirement>
}
