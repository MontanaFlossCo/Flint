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

    func testAvailabilityOfChildFeatureThatIsUnavailableAndThenPurchased() {
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

    /// Verify that all the conditional features in the ancestry need to be purchased for
    /// the child to be available.
    func testAvailabilityOfChildFeatureWithParentThatIsUnavailableAndThenPurchased() {
        Flint.setup(ConditionalParentFeatureA.self)
        
        // At first we don't know if the parent is purchased
        XCTAssertTrue(checker.isAvailable(ConditionalParentFeatureA.self) == nil)

        // Then we know we don't have it (data loaded)
        fakePurchases.confirmNotPurchased(productC)
        XCTAssertTrue(checker.isAvailable(ConditionalParentFeatureA.self) == false)

        // Then we purchase the parent
        fakePurchases.makeFakePurchase(productC)
        XCTAssertTrue(checker.isAvailable(ConditionalParentFeatureA.self) == true)

        // The child should still not be available, as the child itself has not been purchased
        XCTAssertTrue(checker.isAvailable(ConditionalFeatureC.self) != true)

        // Purchase the child
        fakePurchases.makeFakePurchase(productD)

        // The child should now be available
        XCTAssertTrue(checker.isAvailable(ConditionalFeatureC.self) == true)
    }
    
    func testPermissions() {
        Flint.setup(ParentFeatureA.self)
        
        // At first we don't know if the parent is purchased
        XCTAssertTrue(checker.isAvailable(ConditionalFeatureWithPermissionRequirements.self) == false)

    }
}


fileprivate let productA = Product(name: "Product A", description: "This is product A", productID: "PROD-A")
fileprivate let productB = Product(name: "Product B", description: "This is product B", productID: "PROD-B")
fileprivate let productC = Product(name: "Product C", description: "This is product C", productID: "PROD-C")
fileprivate let productD = Product(name: "Product D", description: "This is product D", productID: "PROD-D")

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
        ConditionalFeatureB.self,
        ConditionalFeatureWithPermissionRequirements.self
    ]
    
    static func prepare(actions: FeatureActionsBuilder) {
    }
}

final private class ConditionalFeatureC: ConditionalFeature {
    static var description: String = ""
    
    static var availability: FeatureAvailability = .purchaseRequired(requirement: PurchaseRequirement(productD))
    
    static var isAvailable: Bool? = false

    static func prepare(actions: FeatureActionsBuilder) {
    }
}

final private class ConditionalParentFeatureA: FeatureGroup, ConditionalFeature {
    static var availability: FeatureAvailability = .purchaseRequired(requirement: PurchaseRequirement(productC))
    
    static var description: String = ""
    
    static var subfeatures: [FeatureDefinition.Type] = [
        ConditionalFeatureC.self
    ]
    
    static func prepare(actions: FeatureActionsBuilder) {
    }
}

final private class ConditionalFeatureWithPermissionRequirements: ConditionalFeature, PermissionsRequired {
    static var availability: FeatureAvailability = .custom(isAvailable: { true })
    static var requiredPermissions: Set<Permission> = [.camera]

    static var description: String = ""
    
    static var subfeatures: [FeatureDefinition.Type] = [
        ConditionalFeatureC.self
    ]
    
    static func prepare(actions: FeatureActionsBuilder) {
    }
}

