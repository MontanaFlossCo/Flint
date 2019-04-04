//
//  PurchaseBrowserViewController.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 20/02/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import FlintCore

/// A simple presentation of the current status of purchases, as returned by
/// Flint's current `purchaseTracker` implementation.
///
/// - note: This has special support for `DebugPurchaseTracker`, and if it detects
/// that your `Flint.purchaseTracker` that type, you will be able to use the UI to override
/// the status of individual purchases
public class PurchaseBrowserViewController: UITableViewController {
 
    public static func instantiate() -> PurchaseBrowserViewController {
        let storyboard = UIStoryboard(name: "FlintUI", bundle: Bundle(for: PurchaseBrowserViewController.self))
        let viewController = storyboard.instantiateViewController(withIdentifier: "PurchaseStatus") as! PurchaseBrowserViewController
        return viewController
    }
    
    public var purchases: [(Product, Bool?)] = []
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.clearsSelectionOnViewWillAppear = false
        
        navigationItem.title = "Purchase Status"
        if navigationController?.viewControllers.first == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissPurchases))
        }

        gatherPurchaseData()
    }
    
    // MARK: Data
    
    func gatherPurchaseData() {
        var allProductsReferenced: Set<Product> = []
        for featureMetadata in Flint.allFeatures {
            featureMetadata.productsRequired.forEach { allProductsReferenced.insert($0) }
        }
        purchases = allProductsReferenced.map {
            switch $0 {
                case let nonConsumableProduct as NonConsumableProduct:
                    return ($0, Flint.purchaseTracker?.isPurchased(nonConsumableProduct))
                default:
                    return ($0, nil)
            }
        }
    }
    
    // MARK: Table View
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return purchases.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductStatus", for: indexPath)
        let item: (product: Product, status: Bool?) = purchases[indexPath.row]
        let statusText: String
        if let status = item.status {
            statusText = status ? "Purchased" : "Not purchased"
        } else {
            statusText = "Unknown"
        }
        cell.textLabel?.text = "\(item.product.name) — \(item.product.description ?? "No description" )"
        cell.detailTextLabel?.text = "\(statusText). \(item.product.productID)"
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry: (product: Product, status: Bool?) = purchases[indexPath.item]
        let statusText: String
        if let status = entry.status {
            statusText = status ? "is purchased" : "is not purchased"
        } else {
            statusText = "status is unknown"
        }
        
        let overrideStatusText: String
        let debugPurchaseTracker = Flint.purchaseTracker as? DebugPurchaseTracker
        let debugOverrideStatus = debugPurchaseTracker?.overridenStatus(for: entry.product)
        if  debugPurchaseTracker != nil {
            if let overrideStatus = debugOverrideStatus {
                switch overrideStatus {
                    case .notPurchased: overrideStatusText = "not purchased"
                    case .purchased: overrideStatusText = "purchased"
                    case .unknown: overrideStatusText = "unknown"
                }
            } else {
                overrideStatusText = "none"
            }
        } else {
            overrideStatusText = "no debug tracker installed"
        }
        
        let message = "\(entry.product.name) \(statusText)\nOverride: \(overrideStatusText)"
        
        let alertController = UIAlertController(title: "Purchase status", message: message, preferredStyle: .actionSheet)
        
        if let overrideTracker = debugPurchaseTracker {
            if debugOverrideStatus != nil &&
                    (entry.product is NonConsumableProduct || entry.product is SubscriptionProduct) {
                alertController.addAction(UIAlertAction(title: "Remove override", style: .default, handler: { _ in
                    switch entry.product {
                        case let nonConsumableProduct as NonConsumableProduct:
                            overrideTracker.invalidatePurchaseOverride(product: nonConsumableProduct)
                        case let subscriptionProduct as SubscriptionProduct:
                            overrideTracker.invalidatePurchaseOverride(product: subscriptionProduct)
                        default:
                            flintBug("We should not be able to remove overrides on product type: \(entry.product)")
                            break
                    }
                    self.refresh()
                }))
            }
            if debugOverrideStatus != .purchased &&
                    (entry.product is NonConsumableProduct || entry.product is SubscriptionProduct) {
                alertController.addAction(UIAlertAction(title: "Simulate purchase", style: .default, handler: { _ in
                    switch entry.product {
                        case let nonConsumableProduct as NonConsumableProduct:
                            overrideTracker.overridePurchase(product: nonConsumableProduct, with: .purchased)
                        case let subscriptionProduct as SubscriptionProduct:
                            overrideTracker.overridePurchase(product: subscriptionProduct, with: .purchased)
                        default:
                            flintBug("We should not be able to remove overrides on product type: \(entry.product)")
                            break
                    }
                    self.refresh()
                }))
            }
            if debugOverrideStatus != .notPurchased &&
                    (entry.product is NonConsumableProduct || entry.product is SubscriptionProduct) {
                alertController.addAction(UIAlertAction(title: "Simulate not purchased", style: .default, handler: { _ in
                    switch entry.product {
                        case let nonConsumableProduct as NonConsumableProduct:
                            overrideTracker.overridePurchase(product: nonConsumableProduct, with: .notPurchased)
                        case let subscriptionProduct as SubscriptionProduct:
                            overrideTracker.overridePurchase(product: subscriptionProduct, with: .notPurchased)
                        default:
                            flintBug("We should not be able to remove overrides on product type: \(entry.product)")
                            break
                    }
                    self.refresh()
                }))
            }
            if debugOverrideStatus != .unknown &&
                    (entry.product is NonConsumableProduct || entry.product is SubscriptionProduct) {
                alertController.addAction(UIAlertAction(title: "Simulate unknown", style: .default, handler: { _ in
                    switch entry.product {
                        case let nonConsumableProduct as NonConsumableProduct:
                            overrideTracker.overridePurchase(product: nonConsumableProduct, with: .unknown)
                        case let subscriptionProduct as SubscriptionProduct:
                            overrideTracker.overridePurchase(product: subscriptionProduct, with: .unknown)
                        default:
                            flintBug("We should not be able to remove overrides on product type: \(entry.product)")
                            break
                    }
                    self.refresh()
                }))
            }
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        } else {
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        }
        
        let sourceFrame = tableView.cellForRow(at: indexPath)!.frame
        let popoverSourceFrame = CGRect(x: sourceFrame.midX, y: sourceFrame.midY, width: 44, height: 44)
        alertController.popoverPresentationController?.sourceView = tableView
        alertController.popoverPresentationController?.sourceRect = popoverSourceFrame
        present(alertController, animated: true)
    }
    
    public func refresh() {
        gatherPurchaseData()
        tableView.reloadData()
    }

    // MARK: Outlets and actions
    
    @objc public func dismissPurchases() {
        if let request = PurchaseBrowserFeature.hide.request() {
            request.perform(input: .animated(true), presenter: self)
        }
    }
    
}
