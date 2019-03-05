//
//  Product.swift
//  FlintCore
//
//  Created by Marc Palmer on 03/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This type represents information about a product that can be purchased in your app, for use in
/// constraining features to specific products. This is not intended to implement a store client for displaying
/// products and purchasing, but you may extend the types to do this.
///
/// This is used by the `purchase` conditional feature constraint, allowing you to bind
/// Features to one or more Product, so that if the product is purchased, a group of features can
/// become available.
///
/// - see: `FeatureAvailability` and `PurchaseRequirement`
///
/// - note: The name and description are primarily used for local debugging. You can use them for your purchase UI
/// in your app but you will need to consider loading the strings for display from a strings bundle using
/// the value of `name` and `description` as keys. For StoreKit usage, you need to retrieve the localized
/// price from the App Store. You could do this with a subclass that lazily loads the prices when required.
///
/// - note: We use class semantics here so that the app can subclass it to include additional properties as required
/// for the purchasing mechanism they use.
public class Product: Hashable, Equatable {
    
    /// The name of the product, for display to the user and debugging. e.g. "Premium Subscription".
    /// To localise, you'll want to use a value that is a key you can resolve against a strings bundle.
    public let name: String

    /// The description of the product, for display primaroily in debugging UIs.
    /// If you want to also show this to users and localise, you'll want to use a value that is a key you can resolve against a strings bundle.
    public let description: String?
    
    /// A product ID used by your purchase subsystem to uniquely identify the product that to be purchased.
    /// For Apple App Store / StoreKit you'll need to use the Product ID you specified when creating the in-app
    /// purchase.
    public let productID: String
    
    public init(name: String, description: String? = nil, productID: String) {
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
