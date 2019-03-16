//
//  MockPurchaseValidator.swift
//  FlintCore
//
//  Created by Marc Palmer on 27/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
@testable import FlintCore

/// A mock purchase validator that can simulate purchases or verification that items are not purchased.
class MockPurchaseValidator: PurchaseTracker {
    
    var observers = ObserverSet<PurchaseTrackerObserver>()
    var fakePurchases: [String:Bool] = [:]
    
    func addObserver(_ observer: PurchaseTrackerObserver) {
        observers.add(observer, using: SmartDispatchQueue(queue: .main))
    }
    
    func removeObserver(_ observer: PurchaseTrackerObserver) {
        observers.remove(observer)
    }
    
    /// Call this to fake confirmation that a purchase has not been made on this product.
    /// Until the purchase subsystem has checked receipts, the status of such features is unknown.
    public func confirmNotPurchased(_ product: NonConsumableProduct) {
        setPurchased(product, purchased: false)
    }
    
    /// Call this to fake a purchase
    public func makeFakePurchase(_ product: NonConsumableProduct) {
        setPurchased(product, purchased: true)
    }
    
    public func reset() {
        let copyOfPurchases = fakePurchases
        fakePurchases.removeAll()
        
        for (productID, purchased) in copyOfPurchases {
            observers.notifySync { observer in
                observer.purchaseStatusDidChange(productID: productID, isPurchased: purchased)
            }
        }
    }
    
    private func setPurchased(_ product: NonConsumableProduct, purchased: Bool) {
        fakePurchases[product.productID] = purchased

        observers.notifySync { observer in
            observer.purchaseStatusDidChange(productID: product.productID, isPurchased: purchased)
        }
    }

    func isPurchased(_ product: NonConsumableProduct) -> Bool? {
        return fakePurchases[product.productID]
    }
    
    func isSubscriptionActive(_ product: SubscriptionProduct) -> Bool? {
        return nil
    }
    
    func isFeatureEnabledByPastPurchases(_ feature: FeatureDefinition.Type) -> Bool {
        return false
    }
}
