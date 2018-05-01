//
//  DefaultAvailabilityChecker.swift
//  FlintCore
//
//  Created by Marc Palmer on 13/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The standard feature availability checker that supports the user toggling features (in User Defaults) that permit
/// this, as well as purchase-based toggling. It caches the results in order to avoid walking the feature graph
/// every time there is a check.
///
/// To customise behaviour of user toggling, implement `UserFeatureToggles` and pass it in to an instance of this class.
///
/// To customise behaviour of purchase verification, implement `PurchaseValidator` and pass it in to an instance of this class.
///
/// This class implements the `PurchaseRequirement` logic to test if they are all met for features that require purchases.
public class DefaultAvailabilityChecker: AvailabilityChecker {
    public let constraintsEvaluator: ConstraintsEvaluator
    
    /// We store the last result of availability checks here
    private var availabilityCache: [FeaturePath:Bool] = [:]
    
    private let cacheAccessQueue = DispatchQueue(label: "tools.flint.availability-checker")
    
    /// Initialise the availability checker with the supplied feature toggle and purchase validator implementations.
    public init(constraintsEvaluator: ConstraintsEvaluator) {
        self.constraintsEvaluator = constraintsEvaluator
    }
    
    /// Return whether or not the feature is enabled, accordig to its `availability` type.
    public func isAvailable(_ feature: ConditionalFeatureDefinition.Type) -> Bool? {
        return cacheAccessQueue.sync {
            return _isAvailable(feature)
        }
    }
    
    public func invalidate() {
        return cacheAccessQueue.sync {
            return availabilityCache.removeAll()
        }
    }
    
    /// - note: Must only be called on the cacheAccessQueue
    private func _isAvailable(_ feature: ConditionalFeatureDefinition.Type) -> Bool? {
        let featureIdentifier = feature.identifier
        
        // Fast path
        if constraintsEvaluator.canCacheResult(for: feature),
                let cachedAvailable = availabilityCache[featureIdentifier] {
            FlintInternal.logger?.debug("Availability check on \(featureIdentifier) returning cached value of isAvailable: \(cachedAvailable)")
            return cachedAvailable
        }
        
        var available: Bool?
        let evaluation = constraintsEvaluator.evaluate(for: feature)

        switch (evaluation.satisfied.isEmpty, evaluation.unsatisfied.isEmpty, evaluation.unknown.isEmpty) {
            case (_, true, true): available = true
            case (_, false, true): available = false
            case (_, _, false): available = nil
        }
        
        // If it is nil we need to get out here, we don't want to waste any more time checking ancestors
        // and we do't want to cache the results
        guard var seemsAvailable = available else {
            return nil
        }
        
        // Check ancestors, if necessary
        if let conditionalParent = feature.parent as? ConditionalFeatureDefinition.Type {
            if let parentAvailable = _isAvailable(conditionalParent) {
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
        
        // Store it in the cache, if we had any kind of concrete result.
        // Invalidation must occur if we want to re-check in future
        availabilityCache[featureIdentifier] = seemsAvailable
        
        FlintInternal.logger?.debug("Availability check on \(featureIdentifier) resulted in isAvailable: \(seemsAvailable)")
        return seemsAvailable
    }

    /// - note: Must only be called on the cacheAccessQueue
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

extension DefaultAvailabilityChecker: PurchaseTrackerObserver {
    public func purchaseStatusDidChange(productID: String, isPurchased: Bool) {
        invalidate()
    }
}
