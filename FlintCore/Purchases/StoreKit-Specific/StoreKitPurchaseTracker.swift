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
/// to cache the list of purchase statuses. *It does not validate receipts*.
///
/// The local storage is unprotected if the user unlocks the device, and as such may be
/// subject to relatively easy editing by the determined cheapskate user to unlock features.
///
/// - note: ⚠️⚠️⚠️ Do not use this implementation if you insist on cryprographically verifying
/// purchases.
/// - note: ⚠️⚠️⚠️ It is our view that we should rely on the security of Apple's platform and not
/// be overly concerned with users performing hacks and workarounds. People that go to the effort of
/// jailbreaking, re-signing apps or applying other patching or data editing mechanisms
/// are unlikely to have paid you any money anyway.
///
/// If this isn't good enough for you, you will need to add your own app-specific logic to verify this so there isn't a
/// single point of verification, and to check receipts. You may not want to use Flint
/// for purchase verification at all if it transpires that the Swift call sites for
/// conditional requests are easily circumvented.
///
/// - note: In-App Purchases APIs are not available on watchOS as of watchOS 5. Any
/// Feature that requires a purchase will not be enabled on watchOS.
@available(iOS 3, tvOS 9, macOS 10.7, *)
@objc
public class StoreKitPurchaseTracker: NSObject, PurchaseTracker {
    private let purchaseStore: SimplePurchaseStore
    private var observers = ObserverSet<PurchaseTrackerObserver>()
    private var purchases: [String:PurchaseStatus]
    private let logger: ContextSpecificLogger?

    struct PurchaseStatus: Codable {
        let productID: String
        let isPurchased: Bool
    }
    
    /// Instantiate the StoreKit purchase tracker, storing the status of purchases
    /// in the container specified by `appGroupIndentifier`.
    ///
    /// - param appGroupIdentifier: If nil, the information about purchases will be stored
    /// in the app's container. This will not be accessible to other parts of your app, e.g.
    /// app extensions. So if you have extensions you must create an app group container all
    /// extensions use and specify its identifier here.
    public init(appGroupIdentifier: String?) throws {
        logger = Logging.development?.contextualLogger(with: "StoreKit Purchases", topicPath: FlintInternal.coreLoggingTopic.appending("Purchases"))

        purchaseStore = try SimplePurchaseStore(appGroupIdentifier: appGroupIdentifier)
        purchases = [:]
        super.init()

        logger?.debug("Loading purchases")
        try purchaseStore.load().forEach { purchases[$0.productID] = $0 }

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
    public func isPurchased(_ product: NonConsumableProduct) -> Bool? {
        if let productStatus = purchases[product.productID] {
            return productStatus.isPurchased
        } else {
            return nil
        }
    }

    /// Indicate the purchase was successful, and store this fact
    func didPurchase(_ productID: String) throws {
        logger?.debug("Recording purchase of iTunes product ID: \(productID)")
        purchases[productID] = PurchaseStatus(productID: productID, isPurchased: true)
        notifyChange(productID: productID, isPurchased: true)
        try save()
    }

    /// Indicate the purchase is no longer valid, and store this fact
    func didInvalidatePurchase(_ productID: String) throws {
        logger?.debug("Recording invalidation of purchase of iTunes product ID: \(productID)")
        purchases.removeValue(forKey: productID)
        notifyChange(productID: productID, isPurchased: false)
        try save()
    }

    private func notifyChange(productID: String, isPurchased: Bool) {
        observers.notifySync { observer in
            observer.purchaseStatusDidChange(productID: productID, isPurchased: false)
        }
    }
    
    private func save() throws {
        logger?.debug("Saving purchases")
        try purchaseStore.save(productStatuses: Array(purchases.values))
    }
}

extension StoreKitPurchaseTracker: SKPaymentTransactionObserver {

    /// A naïve implementation that assumes all success and restores enable a purchase,
    /// and all failures and deferred remove them - to cater for expiring subscriptionas in a
    /// simple way.
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            logger?.debug("Transaction updated, status: \(transaction.transactionState.rawValue) id: \(transaction.transactionIdentifier != nil ? transaction.transactionIdentifier! : "nil") for payment of product \(transaction.payment.productIdentifier) with quantity \(transaction.payment.quantity)")
            
            let productID = transaction.payment.productIdentifier

            /// !!! TODO: At least salt and hash the product IDs to make it harder to hack?
            switch transaction.transactionState {
                case .purchased, .restored:
                    do {
                        try didPurchase(productID)
                    } catch let error {
                        logger?.error("Failed to save purchase confirmation for \(productID): \(error)")
                    }
                case .failed, .deferred:
                    do {
                        try didInvalidatePurchase(productID)
                    } catch let error {
                        logger?.error("Failed to save purchase invalidation for \(productID): \(error)")
                    }
                default:
                    break
            }
        }
    }
}
