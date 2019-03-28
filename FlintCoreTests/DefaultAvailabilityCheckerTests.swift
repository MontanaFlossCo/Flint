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

        DefaultLoggerFactory.setup(initialDevelopmentLogLevel: .none, initialProductionLogLevel: .none, briefLogging: true)
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
        let precondition = FeaturePreconditionConstraint.purchase(requirement: PurchaseRequirement(productA))
        
        // At first we don't know
        evaluator.setEvaluationResult(for: ConditionalFeatureA.self,
                                      result: _evaluationWith(precondition: _result(precondition, status: .notDetermined)))
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureA.self), nil)

        // Then we know we don't have it (data loaded)
        evaluator.setEvaluationResult(for: ConditionalFeatureA.self,
                                      result: _evaluationWith(precondition: _result(precondition, status: .notSatisfied)))
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureA.self), false)

        // Then we purchase
        evaluator.setEvaluationResult(for: ConditionalFeatureA.self, result: _evaluationWith(precondition: _result(precondition, status: .satisfied)))
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureA.self), true)
    }

    func testAvailabilityOfChildFeatureThatIsUnavailableAndThenPurchased() {
        let precondition = FeaturePreconditionConstraint.purchase(requirement: PurchaseRequirement(productB))
        
        // Then we know we don't have it (data loaded)
        evaluator.setEvaluationResult(for: ConditionalFeatureB.self,
                                      result: _evaluationWith(precondition: _result(precondition, status: .notDetermined)))
        // At first we don't know
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureB.self), nil)

        // Then we know we don't have it (data loaded)
        evaluator.setEvaluationResult(for: ConditionalFeatureB.self,
                                      result: _evaluationWith(precondition: _result(precondition, status: .notSatisfied)))
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureB.self), false)

        // Then we purchase
        evaluator.setEvaluationResult(for: ConditionalFeatureB.self,
                                      result: _evaluationWith(precondition: _result(precondition, status: .satisfied)))
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureB.self), true)
    }

    func _evaluationWith(preconditions: [FeatureConstraintResult<FeaturePreconditionConstraint>]) -> FeatureConstraintsEvaluation {
        return FeatureConstraintsEvaluation(preconditions: Set(preconditions))
    }
    
    func _evaluationWith(precondition: FeatureConstraintResult<FeaturePreconditionConstraint>) -> FeatureConstraintsEvaluation {
        return _evaluationWith(preconditions: [precondition])
    
    }
    
    func _evaluationWith(permissions: [FeatureConstraintResult<SystemPermissionConstraint>]) -> FeatureConstraintsEvaluation {
        return FeatureConstraintsEvaluation(permissions: Set(permissions))
    }
    
    func _evaluationWith(permission: FeatureConstraintResult<SystemPermissionConstraint>) -> FeatureConstraintsEvaluation {
        return _evaluationWith(permissions: [permission])
    
    }
    
    func _result<T>(_ constraint: T, status: FeatureConstraintStatus) -> FeatureConstraintResult<T> where T: FeatureConstraint {
        return FeatureConstraintResult<T>(constraint: constraint, status: status)
    }
    
    func _results<T>(_ constraints: [T], status: FeatureConstraintStatus) -> [FeatureConstraintResult<T>] where T: FeatureConstraint {
        return constraints.map {
            return FeatureConstraintResult<T>(constraint: $0, status: status)
        }
    }
    
    /// Verify that all the conditional features in the ancestry need to be purchased for
    /// the child to be available.
    func testAvailabilityOfChildFeatureWithParentThatIsUnavailableAndThenPurchased() {
        let productCPrecondition = FeaturePreconditionConstraint.purchase(requirement: PurchaseRequirement(productC))
        let productDPrecondition = FeaturePreconditionConstraint.purchase(requirement: PurchaseRequirement(productD))
        
        // At first we don't know if the parent is purchased
        evaluator.setEvaluationResult(for: ConditionalParentFeatureA.self,
                                      result: _evaluationWith(precondition: _result(productCPrecondition, status: .notDetermined)))
        XCTAssertEqual(checker.isAvailable(ConditionalParentFeatureA.self), nil)

        // Then we know we don't have it (data loaded)
        evaluator.setEvaluationResult(for: ConditionalParentFeatureA.self,
                                      result: _evaluationWith(precondition: _result(productCPrecondition, status: .notSatisfied)))
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalParentFeatureA.self), false)

        // Then we purchase the parent
        evaluator.setEvaluationResult(for: ConditionalParentFeatureA.self,
                                      result: _evaluationWith(precondition: _result(productCPrecondition, status: .satisfied)))
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalParentFeatureA.self), true)

        // Mark all the requirements as unsatisfied
        evaluator.setEvaluationResult(for: ConditionalFeatureC.self, result: _evaluationWith(precondition: _result(productCPrecondition, status: .satisfied)))
        checker.invalidate()
        // The child should still not be available, as the child itself has not been purchased
        XCTAssertNotEqual(checker.isAvailable(ConditionalFeatureC.self), false)

        // Purchase the child but not the parent
        evaluator.setEvaluationResult(for: ConditionalFeatureC.self, result:
            _evaluationWith(preconditions: [_result(productCPrecondition, status: .notSatisfied),
                                            _result(productDPrecondition, status: .satisfied)]))
        checker.invalidate()

        // The child should NOT be available as the parent is still not available
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureC.self), false)

        // Purchase the child AND the parent
        evaluator.setEvaluationResult(for: ConditionalFeatureC.self, result:
            _evaluationWith(preconditions: [_result(productCPrecondition, status: .satisfied),
                                            _result(productDPrecondition, status: .satisfied)]))
        checker.invalidate()

        // The child should NOT be available as the parent is still not available
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureC.self), true)

    }
    
    /// Test the some of the permissions adapters
    func testPermissions() {
        // Check camera permissions
        let cameraPermission = SystemPermissionConstraint.camera
        let photosLocationPermissions = [SystemPermissionConstraint.photos, .location(usage: .whenInUse)]
        
        // Set them to unknown first
        evaluator.setEvaluationResult(for: ConditionalFeatureWithCameraPermissionRequirements.self,
                                      result: _evaluationWith(permission: _result(cameraPermission, status: .notDetermined)))
        evaluator.setEvaluationResult(for: ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self,
                                      result: _evaluationWith(permissions: _results(photosLocationPermissions, status: .notDetermined)))
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureWithCameraPermissionRequirements.self), nil)
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self), nil)
        
        // Set them to unsatifisfied
        evaluator.setEvaluationResult(for: ConditionalFeatureWithCameraPermissionRequirements.self,
                                      result: _evaluationWith(permission: _result(cameraPermission, status: .notSatisfied)))
        evaluator.setEvaluationResult(for: ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self,
                                      result: _evaluationWith(permissions: _results(photosLocationPermissions, status: .notSatisfied)))
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureWithCameraPermissionRequirements.self), false)
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self), false)

        // Set them to satisfied
        evaluator.setEvaluationResult(for: ConditionalFeatureWithCameraPermissionRequirements.self,
                                      result: _evaluationWith(permission: _result(cameraPermission, status: .satisfied)))
        evaluator.setEvaluationResult(for: ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self,
                                      result: _evaluationWith(permissions: _results(photosLocationPermissions, status: .satisfied)))
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureWithCameraPermissionRequirements.self), false)
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self), false)
    }
}


fileprivate let productA = NonConsumableProduct(name: "Product A", description: "This is product A", productID: "PROD-A")
fileprivate let productB = NonConsumableProduct(name: "Product B", description: "This is product B", productID: "PROD-B")
fileprivate let productC = NonConsumableProduct(name: "Product C", description: "This is product C", productID: "PROD-C")
fileprivate let productD = NonConsumableProduct(name: "Product D", description: "This is product D", productID: "PROD-D")

final private class ConditionalFeatureA: ConditionalFeature {
    static var description: String = ""

    static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.purchase(productA)
    }

    static func prepare(actions: FeatureActionsBuilder) {
    }    
}

final private class ConditionalFeatureB: ConditionalFeature {
    static var description: String = ""
    
    static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.purchase(productB)
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
        requirements.purchase(productD)
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

