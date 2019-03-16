//
//  PurchaseValidator.swift
//  FlintCore
//
//  Created by Marc Palmer on 13/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Implement this protocol to verify whether a specific purchase has been paid for.
///
/// You may implement this against whatever receipt system you use, but typically this is StoreKit.
///
/// Flint will call this multiple times for each productID that is required in a `PurchaseRequirement`,
/// so implementations only need to respond to single product requests.
public protocol PurchaseTracker {

    /// Call to add an observer for changes to purchases
    func addObserver(_ observer: PurchaseTrackerObserver)

    /// Call to remove an observer for changes to purchases
    func removeObserver(_ observer: PurchaseTrackerObserver)

    /// Return whether or not the specified product ID has been paid for (and hence features requiring it can be enabled)
    /// by the user.
    /// - note: If the status is not yet known, the implementation can return `nil` to indicate this indeterminate status.
    func isPurchased(_ product: NonConsumableProduct) -> Bool?
    
    /// Return whether or not there is an active subscription for this product, whether it is auto-renewing or not.
    /// - note: If the status is not yet known, the implementation can return `nil` to indicate this indeterminate status.
    func isSubscriptionActive(_ product: SubscriptionProduct) -> Bool?

    /// Return whether or not past purchases, perhaps consumable credits, mean that this feature is currently enabled.
    ///
    /// This is your application's opportunity to implement custom purchase management such as allowing purchase of
    /// specific features with a given number of consumable in-app credits, or a custom cross-device purchase syncing
    /// mechanism, or "grandfathering" users in to new features because they bought the app outright in the past.
    ///
    /// - note: If the status is false, the result of prior calls to `isPurchased` and `isSubscriptionActive` will take precendent
    /// if appropriate. If this function returns `true`, the feature will always be enabled if all its other constraints
    /// are met.
    func isFeatureEnabledByPastPurchases(_ feature: FeatureDefinition.Type) -> Bool
}
