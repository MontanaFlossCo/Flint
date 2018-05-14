//
//  DefaultAvailabilityCheckerTests.swift
//  FlintCore
//
//  Created by Marc Palmer on 27/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import XCTest
@testable import FlintCore
//#if canImport(AVFoundation)
import AVFoundation
//#endif

/// These tests attempt to unit test the DefaultAvailabilityChecker.
///
/// To do this we don't want to bootstrap Flint itself, so we have to manually set up the environment
/// and evaluate the constraints on our test features.
class DefaultAvailabilityCheckerTests: XCTestCase {
 
    var checker: AvailabilityChecker!
    var evaluator: MockFeatureConstraintsEvaluator!
    
    override func setUp() {
        super.setUp()

        // We should never actually be hitting Flint...
        Flint.resetForTesting()

        DefaultLoggerFactory.setup(initialDebugLogLevel: .debug, initialProductionLogLevel: .debug, briefLogging: true)
        Logging.development?.level = .debug

        evaluator = MockFeatureConstraintsEvaluator()
        checker = DefaultAvailabilityChecker(constraintsEvaluator: evaluator)

        evaluateConventions(of: ConditionalFeatureA.self)
        evaluateConventions(of: ConditionalParentFeatureA.self)
        evaluateConventions(of: ConditionalFeatureB.self)
        evaluateConventions(of: ConditionalFeatureC.self)
        evaluateConventions(of: ConditionalFeatureWithCameraPermissionRequirements.self)
        evaluateConventions(of: ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    /// Do the work that Flint would do to set up the constraints etc. for our custom checker here,
    /// as we are not testing the full Flint stack, just the availability checker parts.
    func evaluateConventions(of feature: FeatureDefinition.Type) {
        if let conditionalFeature = feature as? ConditionalFeatureDefinition.Type {
            let builder = DefaultFeatureConstraintsBuilder()
            let constraints = builder.build(conditionalFeature.constraints)
            evaluator.set(constraints: constraints, for: conditionalFeature)
        }
    }
    
    func testAvailabilityOfRootFeatureThatIsUnavailableAndThenPurchased() {
        let precondition = FeatureConstraints([FeaturePrecondition.purchase(requirement: PurchaseRequirement(productA))])
        
        // At first we don't know
        evaluator.setEvaluationResult(for: ConditionalFeatureA.self,
                                      result: FeatureEvaluationResult(unknown: precondition))
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureA.self), nil)

        // Then we know we don't have it (data loaded)
        evaluator.setEvaluationResult(for: ConditionalFeatureA.self,
                                      result: FeatureEvaluationResult(unsatisfied: precondition))
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureA.self), false)

        // Then we purchase
        evaluator.setEvaluationResult(for: ConditionalFeatureA.self, result: FeatureEvaluationResult(satisfied: precondition))
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureA.self), true)
    }

    func testAvailabilityOfChildFeatureThatIsUnavailableAndThenPurchased() {
        let precondition = FeatureConstraints([FeaturePrecondition.purchase(requirement: PurchaseRequirement(productB))])
        
        // Then we know we don't have it (data loaded)
        evaluator.setEvaluationResult(for: ConditionalFeatureB.self,
                                      result: FeatureEvaluationResult(unknown: precondition))
        // At first we don't know
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureB.self), nil)

        // Then we know we don't have it (data loaded)
        evaluator.setEvaluationResult(for: ConditionalFeatureB.self,
                                      result: FeatureEvaluationResult(unsatisfied: precondition))
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureB.self), false)

        // Then we purchase
        evaluator.setEvaluationResult(for: ConditionalFeatureB.self,
                                      result: FeatureEvaluationResult(satisfied: precondition))
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureB.self), true)
    }

    /// Verify that all the conditional features in the ancestry need to be purchased for
    /// the child to be available.
    func testAvailabilityOfChildFeatureWithParentThatIsUnavailableAndThenPurchased() {
        let productCPrecondition = FeatureConstraints([FeaturePrecondition.purchase(requirement: PurchaseRequirement(productC))])
        let productDPrecondition = FeatureConstraints([FeaturePrecondition.purchase(requirement: PurchaseRequirement(productD))])
        let productCandDPrecondition = FeatureConstraints([
            FeaturePrecondition.purchase(requirement: PurchaseRequirement(productC)),
            .purchase(requirement: PurchaseRequirement(productD))
        ])

        // At first we don't know if the parent is purchased
        evaluator.setEvaluationResult(for: ConditionalParentFeatureA.self,
                                      result: FeatureEvaluationResult(unknown: productCPrecondition))
        XCTAssertEqual(checker.isAvailable(ConditionalParentFeatureA.self), nil)

        // Then we know we don't have it (data loaded)
        evaluator.setEvaluationResult(for: ConditionalParentFeatureA.self,
                                      result: FeatureEvaluationResult(unsatisfied: productCPrecondition))
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalParentFeatureA.self), false)

        // Then we purchase the parent
        evaluator.setEvaluationResult(for: ConditionalParentFeatureA.self,
                                      result: FeatureEvaluationResult(satisfied: productCPrecondition))
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalParentFeatureA.self), true)

        // Mark all the requirements as unsatisfied
        evaluator.setEvaluationResult(for: ConditionalFeatureC.self, result: FeatureEvaluationResult(satisfied: productCPrecondition))
        checker.invalidate()
        // The child should still not be available, as the child itself has not been purchased
        XCTAssertNotEqual(checker.isAvailable(ConditionalFeatureC.self), false)

        // Purchase the child but not the parent
        evaluator.setEvaluationResult(for: ConditionalFeatureC.self, result: FeatureEvaluationResult(satisfied: productDPrecondition, unsatisfied: productCPrecondition, unknown: .empty))
        checker.invalidate()

        // The child should NOT be available as the parent is still not available
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureC.self), false)

        // Purchase the child AND the parent
        evaluator.setEvaluationResult(for: ConditionalFeatureC.self, result: FeatureEvaluationResult(satisfied: productCandDPrecondition))
        checker.invalidate()

        // The child should NOT be available as the parent is still not available
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureC.self), true)

    }
    
    /// Test the some of the permissions adapters
    func testPermissions() {
        // Check camera permissions
        let cameraPrecondition = FeatureConstraints([SystemPermission.camera])
        let photosLocationPrecondition = FeatureConstraints([SystemPermission.photos, .location(usage: .whenInUse)])
        evaluator.setEvaluationResult(for: ConditionalFeatureWithCameraPermissionRequirements.self, result: FeatureEvaluationResult(unknown: cameraPrecondition))
        evaluator.setEvaluationResult(for: ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self, result: FeatureEvaluationResult(unknown: photosLocationPrecondition))
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureWithCameraPermissionRequirements.self), nil)
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self), nil)
        
        evaluator.setEvaluationResult(for: ConditionalFeatureWithCameraPermissionRequirements.self, result: FeatureEvaluationResult(unsatisfied: cameraPrecondition))
        evaluator.setEvaluationResult(for: ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self, result: FeatureEvaluationResult(unsatisfied: photosLocationPrecondition))
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureWithCameraPermissionRequirements.self), false)
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self), false)

        evaluator.setEvaluationResult(for: ConditionalFeatureWithCameraPermissionRequirements.self, result: FeatureEvaluationResult(satisfied: cameraPrecondition))
        evaluator.setEvaluationResult(for: ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self, result: FeatureEvaluationResult(satisfied: photosLocationPrecondition))
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureWithCameraPermissionRequirements.self), false)
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self), false)
    }
}


fileprivate let productA = Product(name: "Product A", description: "This is product A", productID: "PROD-A")
fileprivate let productB = Product(name: "Product B", description: "This is product B", productID: "PROD-B")
fileprivate let productC = Product(name: "Product C", description: "This is product C", productID: "PROD-C")
fileprivate let productD = Product(name: "Product D", description: "This is product D", productID: "PROD-D")

final private class ConditionalFeatureA: ConditionalFeature {
    static var description: String = ""

    static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.purchase(PurchaseRequirement(productA))
    }

    static func prepare(actions: FeatureActionsBuilder) {
    }    
}

final private class ConditionalFeatureB: ConditionalFeature {
    static var description: String = ""
    
    static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.purchase(PurchaseRequirement(productB))
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
        requirements.purchase(PurchaseRequirement(productD))
    }
    
    static func prepare(actions: FeatureActionsBuilder) {
    }
}

final private class ConditionalParentFeatureA: FeatureGroup, ConditionalFeature {
    static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.purchase(PurchaseRequirement(productC))
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
        requirements.runtimeEnabled()
        
        requirements.permission(.camera)
    }
    
    public static var isEnabled: Bool? = true

    static var description: String = ""
    
    static func prepare(actions: FeatureActionsBuilder) {
    }
}

final private class ConditionalFeatureWithPhotosAndLocationPermissionRequirements: ConditionalFeature {
    static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.runtimeEnabled()
        
        requirements.permission(.camera)
        requirements.permission(.location(usage: .whenInUse))
    }

    public static var isEnabled: Bool? = true

    static var description: String = ""
    
    static func prepare(actions: FeatureActionsBuilder) {
    }
}

