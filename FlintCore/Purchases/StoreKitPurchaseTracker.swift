//
//  StoreKitPurchaseTracker.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 16/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import StoreKit

/// Example of validation of features by StoreKit In-App Purchase or subscription ID.
///
/// Note that this code could be easily hacked on jailbroken devices. You may need to add your
/// own app-specific logic to verify this so there isn't a single point of verification,
/// and to check receipts.
public class StoreKitPurchaseTracker: PurchaseTracker {

    private var observers = ObserverSet<PurchaseTrackerObserver>()

    public func addObserver(_ observer: PurchaseTrackerObserver) {
        let queue = SmartDispatchQueue(queue: .main, owner: self)
        observers.add(observer, using: queue)
    }
    
    public func removeObserver(_ observer: PurchaseTrackerObserver) {
        observers.remove(observer)
    }

    /// Called to see if a specific product has been purchased
    public func isPurchased(_ productID: String) -> Bool? {
        // 1. Get list of purchases, or bail out if not ready yet
        // let verifiedPurchases: [String] = []

        // 2. Map to products
        // let products = Flint.products.filter { return verifiedPurchases.contains($0) }
       
        // 3. Check requirement
        // return requirement.isFulfilled(verifiedPurchasedProducts: products as Set)
        preconditionFailure("IAP checking is not implemented yet")
    }
    
}
