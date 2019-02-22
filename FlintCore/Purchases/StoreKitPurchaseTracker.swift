//
//  StoreKitPurchaseTracker.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 16/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS) || os(macOS)
import StoreKit
#endif

/// A basic StoreKit In-App Purchase checker that uses only the payment queue and *local storage*
/// to cache the list of purchases. It does not validate receipts.
///
/// The local storage is unencrypted if the user unlocks the device, and as such may be
/// subject to relatively easy editing by the determined cheapskate user to unlock features.
///
/// - note: ⚠️⚠️⚠️ Do not use this implementation if you insist on cryprographically verifying
/// purchases. ⚠️⚠️⚠️ It is our view that we should rely on the security of Apple's platform and not
/// be overly concerned with users performing hacks and workarounds. People that go to the effort of
/// jailbreaking, re-signing apps or applying other patching or data editing mechanisms
/// are unlikely to have paid you any money anyway.
///
/// So remember this code could be easily hacked by people who don't want to pay you.
/// If this isn't good enough for you, you will need to add your own app-specific logic to verify this so there isn't a
/// single point of verification, and to check receipts. You may not want to use Flint
/// for purchase verification at all if it transpires that the Swift call sites for
/// conditional requests are easily circumvented.
///
/// - note: In-App Purchases are not available on watchOS as of watchOS 5
@available(iOS 3, tvOS 9, macOS 10.7, *)
@objc
public class StoreKitPurchaseTracker: NSObject, PurchaseTracker {
    private let purchaseStore: SimplePurchaseStore
    private var observers = ObserverSet<PurchaseTrackerObserver>()
    private var purchases: Set<String> = []
    
    public init(appGroupIdentifier: String?) throws {
        purchaseStore = try SimplePurchaseStore(appGroupIdentifier: appGroupIdentifier)
        let purchases = try purchaseStore.load()
        self.purchases = Set(purchases)
        
        super.init()
        
        SKPaymentQueue.default().add(self)
    }

    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    public func addObserver(_ observer: PurchaseTrackerObserver) {
        let queue = SmartDispatchQueue(queue: .main)
        observers.add(observer, using: queue)
    }
    
    public func removeObserver(_ observer: PurchaseTrackerObserver) {
        observers.remove(observer)
    }

    /// Called to see if a specific product has been purchased
    public func isPurchased(_ productID: String) -> Bool? {
        return purchases.contains(productID)
    }
    
    
}

extension StoreKitPurchaseTracker: SKPaymentTransactionObserver {

    /// A naïve implementation that assumes all success and restores enable a purchase,
    /// and all failures and deferred remove them - to cater for expiring subscriptionas in a
    /// simple way.
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            let productID = transaction.payment.productIdentifier

            /// !!! TODO: At least salt and hash the product IDs?
            switch transaction.transactionState {
                case .purchased, .restored:
                    purchases.insert(productID)
                    observers.notifySync { observer in
                        observer.purchaseStatusDidChange(productID: productID, isPurchased: true)
                    }
                case .failed, .deferred:
                    purchases.remove(productID)
                    observers.notifySync { observer in
                        observer.purchaseStatusDidChange(productID: productID, isPurchased: false)
                    }
                default:
                    break
            }
        }
    }
}
