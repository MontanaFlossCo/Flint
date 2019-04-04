//
//  FeatureConstraintsBuilder+Extensions.swift
//  FlintCore
//
//  Created by Marc Palmer on 14/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Syntactic sugar
public extension FeatureConstraintsBuilder {
    /// Call to declare a list of permissions that your feature requires.
    func permissions(_ requirements: SystemPermissionConstraint...) {
        for requirement in requirements {
            permission(requirement)
        }
    }

    /// Call to declare a list of purchase requirements that your feature requires
    func purchases(_ requirements: PurchaseRequirement...) {
        for requirement in requirements {
            purchase(requirement)
        }
    }

    /// Convenience function for use when constructing constraints in the constraints builder, where
    /// any of the listed requirements will fulfil the requirement. Used for mixing non-consumable and consumable requirements:
    ///
    /// ```
    /// requirements.purchase(anyOf: .init(nonConsumableProduct), .init(creditsProduct, quantity: 5))
    /// ```
    func purchase(anyOf requirements: PurchaseRequirement...) {
        purchase(PurchaseRequirement(products: [], quantity: nil, matchingCriteria: .any, dependencies:requirements))
    }
    
    /// Convenience function for use when constructing constraints in the constraints builder, where
    /// all of the listed requirements must be fulfilled to fulfil the requirement. Used for mixing non-consumable and consumable requirements:
    ///
    /// ```
    /// requirements.purchase(allOf: .init(nonConsumableProduct), .init(creditsProduct, quantity: 5))
    /// ```
    func purchase(allOf requirements: PurchaseRequirement...) {
        purchase(PurchaseRequirement(products: [], quantity: nil, matchingCriteria: .all, dependencies:requirements))
    }
    
    /// Call to declare a product that your feature requires
    func purchase(_ product: NonConsumableProduct) {
        purchase(PurchaseRequirement(product))
    }

    /// Call to declare a product that your feature requires
    func purchase(_ product: ConsumableProduct, quantity: UInt) {
        purchase(PurchaseRequirement(product, quantity: quantity))
    }

    /// Call to declare a product that your feature requires
    func purchase(_ product: SubscriptionProduct) {
        purchase(PurchaseRequirement(product))
    }

    /// Call to declare a list of products that your feature requires. All must be purchased for the constraint to be met
    func purchases(_ products: NonConsumableProduct...) {
        purchase(PurchaseRequirement(products: Set(products), matchingCriteria: .all))
    }

    /// Convenience function for use when constructing constraints in the constraints builder, where
    /// any of the listed purchases will fulfil the requirement
    func purchase(anyOf products: Set<NoQuantityProduct>) {
        purchase(PurchaseRequirement(products: products, quantity: nil, matchingCriteria: .any))
    }
    
    /// Convenience function for use when constructing constraints in the constraints builder, where
    /// any of the listed purchases will fulfil the requirement
    func purchase(anyOf products: NoQuantityProduct...) {
        purchase(PurchaseRequirement(products: Set(products), quantity: nil, matchingCriteria: .any))
    }
    
    /// Convenience function for use when constructing constraints in the constraints builder, where
    /// all of the listed purchases will fulfil the requirement
    func purchase(allOf products: NoQuantityProduct...) {
        purchase(PurchaseRequirement(products: Set(products), quantity: nil, matchingCriteria: .all))
    }
    
    /// Convenience function for use when constructing constraints in the constraints builder, where
    /// all of the listed purchases will fulfil the requirement
    func purchase(allOf products: Set<NoQuantityProduct>) {
        purchase(PurchaseRequirement(products: products, quantity: nil, matchingCriteria: .all))
    }
    
}

/// Platform versions
public extension FeatureConstraintsBuilder {
    
    /// Set this to the minimum iOS version your feature requires
    var iOS: PlatformVersionConstraint {
        get {
            flintUsageError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .iOS, version: newValue))
        }
    }

    /// Set this to the minimum iOS version your feature requires, if it only supports iOS and all other platforms
    /// should be set to `.unsupported`
    var iOSOnly: PlatformVersionConstraint {
        get {
            flintUsageError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .macOS, version: .unsupported))
            self.platform(.init(platform: .tvOS, version: .unsupported))
            self.platform(.init(platform: .watchOS, version: .unsupported))
            self.platform(.init(platform: .iOS, version: newValue))
        }
    }

    /// Set this to the minimum watchOS version your feature requires
    var watchOS: PlatformVersionConstraint {
        get {
            flintUsageError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .watchOS, version: newValue))
        }
    }

    /// Set this to the minimum watchOS version your feature requires, if it only supports watchOS and all other platforms
    /// should be set to `.unsupported`
    var watchOSOnly: PlatformVersionConstraint {
        get {
            flintUsageError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .macOS, version: .unsupported))
            self.platform(.init(platform: .tvOS, version: .unsupported))
            self.platform(.init(platform: .watchOS, version: newValue))
            self.platform(.init(platform: .iOS, version: .unsupported))
        }
    }

    /// Set this to the minimum tvOS version your feature requires
    var tvOS: PlatformVersionConstraint {
        get {
            flintUsageError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .tvOS, version: newValue))
        }
    }

    /// Set this to the minimum tvOS version your feature requires, if it only supports tvOS and all other platforms
    /// should be set to `.unsupported`
    var tvOSOnly: PlatformVersionConstraint {
        get {
            flintUsageError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .macOS, version: .unsupported))
            self.platform(.init(platform: .tvOS, version: newValue))
            self.platform(.init(platform: .watchOS, version: .unsupported))
            self.platform(.init(platform: .iOS, version: .unsupported))
        }
    }

    /// Set this to the minimum macOS version your feature requires
    var macOS: PlatformVersionConstraint {
        get {
            flintUsageError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .macOS, version: newValue))
        }
    }

    /// Set this to the minimum macOS version your feature requires, if it only supports macOS and all other platforms
    /// should be set to `.unsupported`
    var macOSOnly: PlatformVersionConstraint {
        get {
            flintUsageError("Not supported, you can only assign in this DSL")
        }
        set {
            self.platform(.init(platform: .macOS, version: newValue))
            self.platform(.init(platform: .tvOS, version: .unsupported))
            self.platform(.init(platform: .watchOS, version: .unsupported))
            self.platform(.init(platform: .iOS, version: .unsupported))
        }
    }

}
