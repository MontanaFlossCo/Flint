//
//  DebugPurchaseTracker.swift
//  FlintCore
//
//  Created by Marc Palmer on 10/02/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A purchase tracker that allows manually setting of purchase status.
///
/// This can be used standalone as a fake in-memory purchase tracker, or to proxy
/// another purchase tracker implementation so that you can provide overrides at runtime
/// for easier testing.
///
/// On iOS you can use the FlintUI `PurchaseBrowserFeature` to show a simple UI in your app
/// that will let you view the status of purchases, and if this tracker is used, override the
/// purchase status at runtime for testing.
///
/// - see `PurchaseBrowserFeature`
/// - see `StoreKitPurchaseTracker`
public class DebugPurchaseTracker: PurchaseTracker, PurchaseTrackerObserver {
    public enum OverrideStatus {
        case purchased
        case notPurchased
        case unknown
    }
    
    private let observers = ObserverSet<PurchaseTrackerObserver>()
    
    private let targetPurchaseTracker: PurchaseTracker?
    public private(set) var purchaseOverrides: [String:OverrideStatus] = [:]
    
    /// Initiliase a debug tracker that overrides another purchase tracker, if overrides are applied.
    ///
    /// - param targetPurchaseTracker: The original purchase tracker that will be proxied to override
    /// purchase results.
    public init(targetPurchaseTracker: PurchaseTracker) {
        self.targetPurchaseTracker = targetPurchaseTracker
        targetPurchaseTracker.addObserver(self)
    }
    
    /// Initiliase a debug tracker that acts as the source of truth typically in development builds only.
    /// You must call `overridePurchase()` to enable or disable individual products, or use
    /// the FlintUI `DebugPurchasesViewController` on iOS to toggle them at run time.
    public init() {
        targetPurchaseTracker = nil
    }

    deinit {
        targetPurchaseTracker?.removeObserver(self)
    }
    
    /// Called to force the purchase tracker This must betrue even if the user's real
    /// purchase history indicates otherwise.
    public func overridePurchase(product: NonConsumableProduct, with result: OverrideStatus) {
        purchaseOverrides[product.productID] = result
        observers.notifySync { observer in
            observer.purchaseStatusDidChange(productID: product.productID, isPurchased: isPurchased(product) ?? false)
        }
    }

    /// Called to indicate that the purchase tracker should behave as if this
    /// purchase has *not* been performed. This must be true even if the user's real
    /// purchase history indicates otherwise.
    public func invalidatePurchaseOverride(product: NonConsumableProduct) {
        purchaseOverrides.removeValue(forKey: product.productID)
        observers.notifySync { observer in
            observer.purchaseStatusDidChange(productID: product.productID, isPurchased: isPurchased(product) ?? false)
        }
    }

    /// Called to force the purchase tracker This must betrue even if the user's real
    /// purchase history indicates otherwise.
    public func overridePurchase(product: SubscriptionProduct, with result: OverrideStatus) {
        purchaseOverrides[product.productID] = result
        observers.notifySync { observer in
            observer.purchaseStatusDidChange(productID: product.productID, isPurchased: isSubscriptionActive(product) ?? false)
        }
    }

    /// Called to indicate that the purchase tracker should behave as if this
    /// purchase has *not* been performed. This must be true even if the user's real
    /// purchase history indicates otherwise.
    public func invalidatePurchaseOverride(product: SubscriptionProduct) {
        purchaseOverrides.removeValue(forKey: product.productID)
        observers.notifySync { observer in
            observer.purchaseStatusDidChange(productID: product.productID, isPurchased: isSubscriptionActive(product) ?? false)
        }
    }

    /// - return: The current overriden status of the specified product. This may
    /// be `nil` indicating that there is no override in effect.
    /// - param product: The product for which you want to check the override status
    public func overridenStatus(for product: Product) -> OverrideStatus? {
        return purchaseOverrides[product.productID]
    }
    
    /// - return: The current actual status of the specified product, from the real target
    /// purchase tracker. If there is no real purchase tracker, the result will always be `nil`.
    /// - param product: The product for which you want to check the real status
    public func realStatus(for product: Product) -> Bool? {
        if let nonConsumableProduct = product as? NonConsumableProduct {
            return targetPurchaseTracker?.isPurchased(nonConsumableProduct)
        } else {
            return nil
        }
    }
    
    /// Remove all the overrides in effect
    public func invalidateAllPurchaseOverrides() {
        purchaseOverrides.removeAll()
    }

    // MARK: - Observing the original tracker to filter notifications to the callers
    
    public func purchaseStatusDidChange(productID: String, isPurchased: Bool) {
        // Only propagate status changes from the original tracker if we don't have an override
        if nil == purchaseOverrides[productID] {
            observers.notifySync { observer in
                observer.purchaseStatusDidChange(productID: productID, isPurchased: isPurchased)
            }
        }
    }

    // MARK: - Public API that we proxy

    public func addObserver(_ observer: PurchaseTrackerObserver) {
        let queue = SmartDispatchQueue(queue: .main)
        observers.add(observer, using: queue)
    }
    
    public func removeObserver(_ observer: PurchaseTrackerObserver) {
        observers.remove(observer)
    }
    
    public func isPurchased(_ product: NonConsumableProduct) -> Bool? {
        if let overrideValue = getOverrideStatus(product) {
            return overrideValue
        } else {
            return targetPurchaseTracker?.isPurchased(product)
        }
    }
    
    private func getOverrideStatus(_ product: Product) -> Bool? {
        if let overrideValue = purchaseOverrides[product.productID] {
            switch overrideValue {
                case .purchased: return true
                case .notPurchased: return false
                case .unknown: return nil
            }
        } else {
            return nil
        }
    }

    public func isSubscriptionActive(_ product: SubscriptionProduct) -> Bool? {
        if let overrideValue = getOverrideStatus(product) {
            return overrideValue
        } else {
            return targetPurchaseTracker?.isSubscriptionActive(product)
        }
    }
    
    /// We don't support debug overrides for features as a whole currently
    public func isFeatureEnabledByPastPurchases(_ feature: FeatureDefinition.Type) -> Bool {
        return false
    }
}
