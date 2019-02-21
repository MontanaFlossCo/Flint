//
//  PurchaseBrowserViewController.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 20/02/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import FlintCore

public class PurchaseBrowserViewController: UITableViewController {
 
    public static func instantiate() -> PurchaseBrowserViewController {
        let storyboard = UIStoryboard(name: "FlintUI", bundle: Bundle(for: PurchaseBrowserViewController.self))
        let viewController = storyboard.instantiateViewController(withIdentifier: "PurchaseStatus") as! PurchaseBrowserViewController
        return viewController
    }
    
    public var purchases: [(Product, Bool?)] = []
    var selectedEntry: (Int, (Product, Bool?))?
    
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
        cell.textLabel?.text = "\(item.product.productID) - \(String(describing: item.status))"
        cell.detailTextLabel?.text = "Override?"
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let entry = purchases[indexPath.row]
        selectedEntry = (indexPath.row, entry)
        return indexPath
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry = purchases[indexPath.item]
        let alertController = UIAlertController(title: "Purchase status", message: String(reflecting: entry), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true)
    }
    
    // MARK: Outlets and actions
    
    @objc public func dismissPurchases() {
        if let request = PurchaseBrowserFeature.hide.request() {
            request.perform(input: .animated(true), presenter: self)
        }
    }
    
}
