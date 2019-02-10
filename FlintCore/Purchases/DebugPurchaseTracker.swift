//
//  DebugPurchaseTracker.swift
//  FlintCore
//
//  Created by Marc Palmer on 10/02/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Purchase trackers that support debug overrides of purchases must conform to
/// this protocol for the default Flint debug UI to work.
public class DebugPurchaseTracker: PurchaseTracker, PurchaseTrackerObserver {
    public enum OverrideResult {
        case purchased
        case notPurchased
        case unknown
    }
    
    private let observers = ObserverSet<PurchaseTrackerObserver>()
    
    private let targetPurchaseTracker: PurchaseTracker
    private var purchaseOverrides: [String:OverrideResult] = [:]
    
    /// - param targetPurchaseTracker: The original purchase tracker that will be proxied to override
    /// purchase results.
    public init(targetPurchaseTracker: PurchaseTracker) {
        self.targetPurchaseTracker = targetPurchaseTracker
        targetPurchaseTracker.addObserver(self)
    }
    
    /// Called to force tthe purchase tracker This must betrue even if the user's real
    /// purchase history indicates otherwise.
    public func overridePurchase(purchaseID: String, with result: OverrideResult) {
        purchaseOverrides[purchaseID] = result
    }

    /// Called to indicate that the purchase tracker should behave as if this
    /// purchase has *not* been performed. This must be true even if the user's real
    /// purchase history indicates otherwise.
    public func invalidatePurchaseOverride(purchaseID: String) {
        purchaseOverrides.removeValue(forKey: purchaseID)
        
    }
    
    /// Remove all the overrides
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
            return targetPurchaseTracker.isPurchased(productID)
        }
    }
    
}
