//
//  DefaultAvailabilityCheckerTests.swift
//  FlintCore
//
//  Created by Marc Palmer on 27/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import XCTest
import FlintCore
//#if canImport(AVFoundation)
import AVFoundation
//#endif

class DefaultAvailabilityCheckerTests: XCTestCase {
 
    var checker: AvailabilityChecker!
    var fakeToggles: MockUserToggles!
    var fakePurchases: MockPurchaseValidator!
    var evaluator: DefaultFeatureConstraintsEvaluator!
    
    override func setUp() {
        super.setUp()
        
        Flint.resetForTesting()

        fakeToggles = MockUserToggles()
        fakePurchases = MockPurchaseValidator()
        evaluator = DefaultFeatureConstraintsEvaluator(purchaseTracker: fakePurchases, userToggles: fakeToggles)
        checker = DefaultAvailabilityChecker(constraintsEvaluator: evaluator)
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
    
    /// Test the some of the permissions adapters
    func testPermissions() {
        Flint.setup(ParentFeatureA.self)

        print(String(reflecting: Flint.permissionChecker!))

        // Check camera permissions
#if targetEnvironment(simulator)
        // On simulator we DO have camera permission initially
        XCTAssertTrue(checker.isAvailable(ConditionalFeatureWithCameraPermissionRequirements.self) == false)
        XCTAssertTrue(checker.isAvailable(ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self) == false)
#else
        // On device we should NOT have camera permission initially
        XCTAssertTrue(checker.isAvailable(ConditionalFeatureWithCameraPermissionRequirements.self) == false)
        XCTAssertTrue(checker.isAvailable(ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self) == false)
#endif
    }
}


fileprivate let productA = Product(name: "Product A", description: "This is product A", productID: "PROD-A")
fileprivate let productB = Product(name: "Product B", description: "This is product B", productID: "PROD-B")
fileprivate let productC = Product(name: "Product C", description: "This is product C", productID: "PROD-C")
fileprivate let productD = Product(name: "Product D", description: "This is product D", productID: "PROD-D")

final private class ConditionalFeatureA: ConditionalFeature {
    static var description: String = ""

    static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.precondition(.purchase(requirement: PurchaseRequirement(productA)))
    }

    static func prepare(actions: FeatureActionsBuilder) {
    }    
}

final private class ConditionalFeatureB: ConditionalFeature {
    static var description: String = ""
    
    static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.precondition(.purchase(requirement: PurchaseRequirement(productB)))
    }

    static func prepare(actions: FeatureActionsBuilder) {
    }
}

final private class ParentFeatureA: FeatureGroup {
    static var description: String = ""

    static var subfeatures: [FeatureDefinition.Type] = [
        ConditionalFeatureB.self,
        ConditionalFeatureWithCameraPermissionRequirements.self,
        ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self
    ]
    
    static func prepare(actions: FeatureActionsBuilder) {
    }
}

final private class ConditionalFeatureC: ConditionalFeature {
    static var description: String = ""
    
    static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.precondition(.purchase(requirement: PurchaseRequirement(productD)))
    }
    
    static func prepare(actions: FeatureActionsBuilder) {
    }
}

final private class ConditionalParentFeatureA: FeatureGroup, ConditionalFeature {
    static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.precondition(.purchase(requirement: PurchaseRequirement(productC)))
    }
    
    static var description: String = ""
    
    static var subfeatures: [FeatureDefinition.Type] = [
        ConditionalFeatureC.self
    ]
    
    static func prepare(actions: FeatureActionsBuilder) {
    }
}

final private class ConditionalFeatureWithCameraPermissionRequirements: ConditionalFeature {
    static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.precondition(.runtimeEnabled)
        
//        requirements.permission(.camera)
    }
    
    public static var enabled = true

    static var description: String = ""
    
    static func prepare(actions: FeatureActionsBuilder) {
    }
}

final private class ConditionalFeatureWithPhotosAndLocationPermissionRequirements: ConditionalFeature {
    static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.precondition(.runtimeEnabled)
        
//        requirements.permission(.photos)
//        requirements.permission(.location(usage: .whenInUse))
    }
    public static var enabled = true

    static var description: String = ""
    
    static func prepare(actions: FeatureActionsBuilder) {
    }
}

