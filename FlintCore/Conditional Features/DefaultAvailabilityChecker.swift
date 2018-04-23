//
//  DefaultAvailabilityChecker.swift
//  FlintCore
//
//  Created by Marc Palmer on 13/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The standard feature availability checker that supports the user toggling features (in User Defaults) that permit
/// this, as well as purchase-based toggling.
///
/// To customise behaviour of user toggling, implement `UserFeatureToggles` and pass it in to an instance of this class.
///
/// To customise behaviour of purchase verification, implement `PurchaseValidator` and pass it in to an instance of this class.
///
/// This class implements the `PurchaseRequirement` logic to test if they are all met for features that require purchases.
public class DefaultAvailabilityChecker: AvailabilityChecker {
    public let userFeatureToggles: UserFeatureToggles?
    public let purchaseValidator: PurchaseValidator?

    /// Default shared instance using the default validators
#if !os(watchOS)
    public static let instance = DefaultAvailabilityChecker(
        userFeatureToggles: UserDefaultsFeatureToggles(),
        purchaseValidator: StoreKitPurchaseValidator())
#else
    public static let instance = DefaultAvailabilityChecker(
        userFeatureToggles: UserDefaultsFeatureToggles(),
        purchaseValidator: nil)
#endif

    /// Initialise the availability checker with the supplied feature toggle and purchase validator implementations.
    public init(userFeatureToggles: UserFeatureToggles?, purchaseValidator: PurchaseValidator?) {
        self.userFeatureToggles = userFeatureToggles
        self.purchaseValidator = purchaseValidator
    }
    
    /// Return whether or not the feature is enabled, accordig to its `availability` type.
    public func isAvailable(_ feature: ConditionalFeatureDefinition.Type) -> Bool? {
        switch feature.availability {
            case .runtimeEvaluated:
                preconditionFailure("Feature \(feature) is specified with availability \".runtimeEvaluated\" but has not overridden " +
                                    "the \"isAvailable\" property to return whether or not it is available")
            case .userToggled:
                return userFeatureToggles?.isEnabled(feature) ?? false
            case .purchaseRequired(let requirement):
                if let validator = purchaseValidator {
                    return requirement.isFulfilled(validator: validator)
                } else {
                    return nil
                }
        }
    }
}
