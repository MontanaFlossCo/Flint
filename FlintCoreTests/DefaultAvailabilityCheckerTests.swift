//
//  DefaultAvailabilityCheckerTests.swift
//  FlintCore
//
//  Created by Marc Palmer on 27/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import XCTest
import FlintCore

class DefaultAvailabilityCheckerTests: XCTestCase {
 
    var checker: AvailabilityChecker!
    var fakeToggles: MockUserToggles!
    var fakePurchases: MockPurchaseValidator!

    override func setUp() {
        super.setUp()
        
        Flint.resetForTesting()

        fakeToggles = MockUserToggles()
        fakePurchases = MockPurchaseValidator()
        checker = DefaultAvailabilityChecker(userFeatureToggles: fakeToggles, purchaseValidator: fakePurchases)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAvailabilityOfRootFeatureThatIsUnavailableAndThenPurchased() {
        // At first we don't know
        XCTAssertTrue(checker.isAvailable(ConditionalFeatureA.self) == nil)

        // Then we know we don't have it (data loaded)
        fakePurchases.confirmNotPurchased(productA)
        XCTAssertTrue(checker.isAvailable(ConditionalFeatureA.self) == false)

        // Then we purchase
        fakePurchases.makeFakePurchase(productA)
        XCTAssertTrue(checker.isAvailable(ConditionalFeatureA.self) == true)
    }

    func testAvailabilityOfChildFeatureThatIsUnavailable() {
        Flint.setup(ParentFeatureA.self)
        
        // At first we don't know
        XCTAssertTrue(checker.isAvailable(ConditionalFeatureB.self) == nil)

        // Then we know we don't have it (data loaded)
        fakePurchases.confirmNotPurchased(productB)
        XCTAssertTrue(checker.isAvailable(ConditionalFeatureB.self) == false)

        // Then we purchase
        fakePurchases.makeFakePurchase(productB)
        XCTAssertTrue(checker.isAvailable(ConditionalFeatureB.self) == true)
    }
}

fileprivate let productA = Product(name: "Product A", description: "This is product A", productID: "PROD-A")
fileprivate let productB = Product(name: "Product B", description: "This is product B", productID: "PROD-B")

final private class ConditionalFeatureA: ConditionalFeature {
    static var description: String = ""
    
    static var availability: FeatureAvailability = .purchaseRequired(requirement: PurchaseRequirement(productA))
    
    static var isAvailable: Bool? = false

    static func prepare(actions: FeatureActionsBuilder) {
    }    
}

final private class ConditionalFeatureB: ConditionalFeature {
    static var description: String = ""
    
    static var availability: FeatureAvailability = .purchaseRequired(requirement: PurchaseRequirement(productB))
    
    static var isAvailable: Bool? = false

    static func prepare(actions: FeatureActionsBuilder) {
    }
}

final private class ParentFeatureA: FeatureGroup {
    static var description: String = ""

    static var subfeatures: [FeatureDefinition.Type] = [
        ConditionalFeatureB.self
    ]
    
    static func prepare(actions: FeatureActionsBuilder) {
    }
}

