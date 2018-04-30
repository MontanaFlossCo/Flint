//
//  FeatureAvailability.swift
//  FlintCore
//
//  Created by Marc Palmer on 25/11/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// An enum used to indicate how the availability of a feature is determined.
///
/// To actually test if the feature is currently available, use `ConditionalFeatureDefinition.isAvailable`,
/// which must perform the logic to implement this availability
public enum FeatureAvailability {
    /// The feature uses some runtime feature toggling (A/B testing at the level of entire features), runtime
    /// tweaking of availability e.g. setting isAvailable at startup based on data, or remote feature control.
    /// The current value of `enabled` is used to determine availability
    case runtimeEnabled
    
    /// The feature requires one or more purchases, and the `PurchaseValidator` will be required to test whether the purchase
    /// requirements are met.
    /// - see: `PurchaseValidator`
    case purchaseRequired(requirement: PurchaseRequirement)

    /// The feature is user-toggled, e.g. there is some UI or setting that can be used to switch on or off the feature.
    /// By default these are stored by Flint in user preferences.
    /// - see: `DefaultAvailabilityChecker`
    case userToggled(defaultValue: Bool)
}
