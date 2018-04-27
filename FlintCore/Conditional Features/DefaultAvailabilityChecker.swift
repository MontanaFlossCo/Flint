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

    /// We store the last result of availability checks here
    private var availabilityCache: [FeaturePath:Bool] = [:]
    private let cacheAccessQueue = DispatchQueue(label: "tools.flint.availability-checker")

    /// Initialise the availability checker with the supplied feature toggle and purchase validator implementations.
    public init(userFeatureToggles: UserFeatureToggles?, purchaseValidator: PurchaseValidator?) {
        self.userFeatureToggles = userFeatureToggles
        self.purchaseValidator = purchaseValidator
    }
    
    /// Return whether or not the feature is enabled, accordig to its `availability` type.
    public func isAvailable(_ feature: ConditionalFeatureDefinition.Type) -> Bool? {
        return cacheAccessQueue.sync {
            return _isAvailable(feature)
        }
    }
    
    private func _isAvailable(_ feature: ConditionalFeatureDefinition.Type) -> Bool? {
        let featureIdentifier = feature.identifier
        
        // Fast path
        if let cachedAvailable = availabilityCache[featureIdentifier] {
            return cachedAvailable
        }
        
        var available: Bool?
        switch feature.availability {
            case .custom:
                preconditionFailure("Feature \(feature) is specified with availability \".custom\" but has not overridden " +
                                    "the \"isAvailable\" property to return whether or not it is available")
            case .userToggled:
                available = userFeatureToggles?.isEnabled(feature)
            case .purchaseRequired(let requirement):
                if let validator = purchaseValidator {
                    available = requirement.isFulfilled(validator: validator)
                } else {
                    return nil
                }
        }
        
        guard var seemsAvailable = available else {
            return nil
        }
        
        if let conditionalParent = feature.parent as? ConditionalFeatureDefinition.Type {
            if let parentAvailable = isAvailable(conditionalParent) {
                seemsAvailable = seemsAvailable && parentAvailable
            } else {
                return nil
            }
        } else if let parent = feature.parent {
            if let parentAvailable = _isAvailable(parent) {
                seemsAvailable = seemsAvailable && parentAvailable
            } else {
                return nil
            }
        }
        
        availabilityCache[featureIdentifier] = seemsAvailable
        return seemsAvailable
    }

    private func _isAvailable(_ feature: FeatureDefinition.Type) -> Bool? {
        if let conditionalParent = feature.parent as? ConditionalFeatureDefinition.Type {
            if let parentAvailable = _isAvailable(conditionalParent) {
                return parentAvailable
            } else {
                return nil
            }
        } else if let parent = feature.parent {
            return _isAvailable(parent)
        } else {
            return true // non-conditional features with no parent are always availabler
        }
    }
}
