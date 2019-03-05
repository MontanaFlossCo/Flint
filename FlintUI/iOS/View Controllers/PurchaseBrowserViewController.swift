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
            return ($0, Flint.purchaseTracker?.isPurchased($0.productID))
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
            if debugOverrideStatus != nil {
                alertController.addAction(UIAlertAction(title: "Remove override", style: .default, handler: { _ in
                    overrideTracker.invalidatePurchaseOverride(productID: entry.product.productID)
                    self.refresh()
                }))
            }
            if debugOverrideStatus != .purchased {
                alertController.addAction(UIAlertAction(title: "Simulate purchase", style: .default, handler: { _ in
                    overrideTracker.overridePurchase(productID: entry.product.productID, with: .purchased)
                    self.refresh()
                }))
            }
            if debugOverrideStatus != .notPurchased {
                alertController.addAction(UIAlertAction(title: "Simulate not purchased", style: .default, handler: { _ in
                    overrideTracker.overridePurchase(productID: entry.product.productID, with: .notPurchased)
                    self.refresh()
                }))
            }
            if debugOverrideStatus != .unknown {
                alertController.addAction(UIAlertAction(title: "Simulate unknown", style: .default, handler: { _ in
                    overrideTracker.overridePurchase(productID: entry.product.productID, with: .unknown)
                    self.refresh()
                }))
            }
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        } else {
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        }
        
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
