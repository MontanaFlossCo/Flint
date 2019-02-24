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
    public func overridePurchase(productID: String, with result: OverrideStatus) {
        purchaseOverrides[productID] = result
        observers.notifySync { observer in
            observer.purchaseStatusDidChange(productID: productID, isPurchased: isPurchased(productID) ?? false)
        }
    }

    /// Called to indicate that the purchase tracker should behave as if this
    /// purchase has *not* been performed. This must be true even if the user's real
    /// purchase history indicates otherwise.
    public func invalidatePurchaseOverride(productID: String) {
        purchaseOverrides.removeValue(forKey: productID)
        observers.notifySync { observer in
            observer.purchaseStatusDidChange(productID: productID, isPurchased: isPurchased(productID) ?? false)
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
        return targetPurchaseTracker?.isPurchased(product.productID)
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
    
    public func isPurchased(_ productID: String) -> Bool? {
        if let overrideValue = purchaseOverrides[productID] {
            switch overrideValue {
                case .purchased: return true
                case .notPurchased: return false
                case .unknown: return nil
            }
        } else {
            return targetPurchaseTracker?.isPurchased(productID)
        }
    }
    
}
