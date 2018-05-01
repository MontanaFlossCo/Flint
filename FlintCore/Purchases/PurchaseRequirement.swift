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
public class PurchaseRequirement: Hashable, Equatable {
    
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

    /// Initialise the requirement with its products, matching criteria and dependencies.
    public init(products: Set<Product>, matchingCriteria: Criteria, dependencies: [PurchaseRequirement]? = nil) {
        self.products = products
        self.matchingCriteria = matchingCriteria
        self.dependencies = dependencies
    }
    
    public convenience init(_ product: Product) {
        self.init(products: [product], matchingCriteria: .all)
    }
    
    /// Call to see if this requirement and all dependent requirements are fulfilled
    /// - param validator: The validator to use to see if each product in a requirement has been purchased
    public func isFulfilled(validator: PurchaseTracker) -> Bool? {
        let matched: Bool?
        switch matchingCriteria {
            case .any:
                var result: Bool?
                for product in products {
                    result = validator.isPurchased(product.productID)
                    if result == true {
                        break
                    }
                }
                matched = result
            case .all:
                var result: Bool?
                for product in products {
                    result = validator.isPurchased(product.productID)
                    if !(result == true) {
                        break
                    }
                }
                matched = result
        }
        
        if matched == true {
            guard let dependencies = dependencies else {
                return matched
            }
            let firstFailing = dependencies.first(where: { requirement -> Bool in
                return !(requirement.isFulfilled(validator: validator) == true)
            })
            return firstFailing == nil
        } else {
            return matched
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
