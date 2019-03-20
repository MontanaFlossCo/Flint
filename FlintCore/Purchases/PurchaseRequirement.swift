//
//  PurchaseRequirement.swift
//  FlintCore
//
//  Created by Marc Palmer on 03/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Use a `PurchaseRequirement` to express the rules about what purchased products enable your Feature(s).
///
/// You can express complex rules about how your Features are enabled using a graph of requirements.
/// Each Feature can only have one requirement when using the `.purchaseRequired` availability value,
/// but one requirement can match one or all of a list of product IDs, as well as having dependencies on other requirements.
///
/// With this you can express the following kinds of rules:
///
/// * Feature X is available if Product A is purchased
/// * Feature X is available if Product A OR Product B OR Product C is purchased
/// * Feature X is available if Product A AND Product B AND Product C is purchased
/// * Feature X is available if Product A AND (Product B OR Product C) is purchased
/// * Feature X is available if (Product A OR Product B) AND ((Product B OR Product C) AND PRODUCT D) is purchased
/// * Feature X is available if (Product A OR Product B) AND ((Product B OR Product C) AND PRODUCT D AND PRODUCT E) is purchased
///
/// ...and so on. This allows you to map Feature availability to a range of different product pricing strategies and relationships,
/// such as "Basic" level of subscription plus a "Founder" IAP that maybe offered to unlock all features in future for a one-off purchase,
/// provided they still have a basic subscription.
public class PurchaseRequirement: Hashable, Equatable, CustomStringConvertible {
    
    /// An enum type that determines how a products are matched.
    public enum Criteria: Hashable, Equatable {
        /// The requirement rule will be met if any of the products have been purchased
        case any

        /// The requirement rule will be met only if all of the products have been purchased
        case all
    }
    
    /// The set of products to match with this requirement
    public let products: Set<Product>
    
    /// Determines how products are matched. Specifying `.any` means at least one product has to be purchased to fulfull this requirement.
    /// Using `.all` means every product in the `products` set must be purchased for this requirement to be fulfilled.
    public let matchingCriteria: Criteria
    
    /// Optional list of requirements that must also be fulfilled for this requirement to be fulfilled.
    /// Using this you can express complex combinations of purchases and options
    public let dependencies: [PurchaseRequirement]?

    /// The optional quantity of product for this requirement to be met.
    /// This is optional and only relates to ConsumableProduct types, and is *purely informational* because
    /// Flint does not handle allocation of consumable products/credits, but your app can access this information
    /// when you need to show a store UI to unlock the feature.
    public let quantity: UInt?
    
    /// Initialise the requirement with its products, matching criteria and dependencies.
    init(products: Set<Product>, quantity: UInt?, matchingCriteria: Criteria, dependencies: [PurchaseRequirement]? = nil) {
        self.products = products
        self.quantity = quantity
        self.matchingCriteria = matchingCriteria
        self.dependencies = dependencies
    }
    
    /// Initialise the requirement with its products, matching criteria and dependencies.
    public convenience init(products: Set<NonConsumableProduct>, matchingCriteria: Criteria, dependencies: [PurchaseRequirement]? = nil) {
        self.init(products: products, quantity: nil, matchingCriteria: matchingCriteria, dependencies: dependencies)
    }
    
    public convenience init(_ product: NonConsumableProduct, dependencies: [PurchaseRequirement]? = nil) {
        self.init(products: [product], matchingCriteria: .all, dependencies: dependencies)
    }
    
    public convenience init(_ product: SubscriptionProduct, dependencies: [PurchaseRequirement]? = nil) {
        self.init(products: [product], quantity: nil, matchingCriteria: .all, dependencies: dependencies)
    }
    
    public convenience init(_ product: ConsumableProduct, quantity: UInt, dependencies: [PurchaseRequirement]? = nil) {
        self.init(products: [product], quantity: quantity, matchingCriteria: .all, dependencies: dependencies)
    }
    
    /// Call to see if this requirement and all dependent requirements are fulfilled
    /// - param validator: The validator to use to see if each product in a requirement has been purchased
    public func isFulfilled(purchaseTracker: PurchaseTracker, feature: ConditionalFeatureDefinition.Type) -> Bool? {
        let matched: Bool?
        switch matchingCriteria {
            case .any:
                var result: Bool?
                for product in products {
                    result = establishFulfilment(of: product, purchaseTracker: purchaseTracker, feature: feature)
                    if result == true {
                        break
                    }
                }
                matched = result
            case .all:
                var result: Bool?
                for product in products {
                    result = establishFulfilment(of: product, purchaseTracker: purchaseTracker, feature: feature)
                    if !(result == true) {
                        break
                    }
                }
                matched = result
        }
        
        // Only evaluate dependencies if this level's requirements are met, or there are no direct requirements at this level
        if matched == true || products.count == 0 {
            guard let dependencies = dependencies else {
                return matched
            }
            let firstFailing = dependencies.first(where: { requirement -> Bool in
                return !(requirement.isFulfilled(purchaseTracker: purchaseTracker, feature: feature) == true)
            })
            return firstFailing == nil
        } else {
            return matched
        }
    }
 
    private func establishFulfilment(of product: Product,
                                     purchaseTracker: PurchaseTracker,
                                     feature: ConditionalFeatureDefinition.Type) -> Bool? {
        var purchased: Bool?
        switch product {
            case let nonConsumableProduct as NonConsumableProduct:
                purchased = purchaseTracker.isPurchased(nonConsumableProduct)
            case let subscriptionProduct as SubscriptionProduct:
                purchased = purchaseTracker.isSubscriptionActive(subscriptionProduct)
            case is ConsumableProduct:
                break
            default:
                flintBug("Unsupported product type: \(product)")
        }
        if purchased == nil || purchased == false {
            if purchaseTracker.isFeatureEnabledByPastPurchases(feature) {
                purchased = true
            }
        }
        return purchased
    }
    
    public var description: String {
        let productDescriptions: [String] = products.map {
            if let descriptionText = $0.description {
                return "\($0.productID): \"\(descriptionText)\""
            } else {
                return $0.productID
            }
        }
        let text = "Purchase requirement for \(productDescriptions.joined(separator: ", ")) (matching: \(matchingCriteria))"
        if let dependencies = dependencies, dependencies.count > 0 {
            let dependencyDescriptions = dependencies.map { $0.description }
            return text + " dependencies: \(dependencyDescriptions.joined(separator: ", "))"
        } else {
            return text
        }
    }
    
    // MARK: Hashable & Equatable Conformances
    
    public var hashValue: Int {
        return products.hashValue ^ matchingCriteria.hashValue
    }
    
    public static func ==(lhs: PurchaseRequirement, rhs: PurchaseRequirement) -> Bool {
        return lhs.products == rhs.products &&
            lhs.matchingCriteria == rhs.matchingCriteria &&
            lhs.dependencies == rhs.dependencies
    }
}
