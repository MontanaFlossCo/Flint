//
//  Product.swift
//  FlintCore
//
//  Created by Marc Palmer on 03/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This type represents information about a product that can be purchased in your app.
///
/// This is used by the `purchaseRequired` conditional feature availability type, allowing you to bind
/// Features to one or more Product, so that if the product is purchased, a group of features can
/// become available.
///
/// - see: `FeatureAvailability` and `PurchaseRequirement`
///
/// - note: We use class semantics here so that the app can subclass it to include additional properties as required
/// for the purchasing mechanism they use.
public class Product: Hashable, Equatable {
    
    /// The name of the product, for display to the user and debugging. e.g. "Premium Subscription"
    public let name: String

    /// The description of the product, for display to the user. e.g. "Unlocks all features"
    public let description: String
    
    /// A product ID used by your purchase subsystem to uniquely identify the product that to be purchased
    public let productID: String
    
    public init(name: String, description: String, productID: String) {
        self.name = name
        self.description = description
        self.productID = productID
    }
    
    public var hashValue: Int {
        return productID.hashValue
    }
    
    public static func ==(lhs: Product, rhs: Product) -> Bool {
        return lhs.productID == rhs.productID
    }
}
