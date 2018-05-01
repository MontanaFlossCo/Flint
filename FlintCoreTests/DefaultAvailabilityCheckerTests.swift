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
    var fakeToggles: MockUserToggles!
    var fakePurchases: MockPurchaseValidator!
    var evaluator: DefaultFeatureConstraintsEvaluator!
    var permissionChecker: PermissionChecker!
    
    override func setUp() {
        super.setUp()

        // We should never actually be hitting Flint...
        Flint.resetForTesting()

        DefaultLoggerFactory.setup(initialDebugLogLevel: .debug, initialProductionLogLevel: .debug, briefLogging: true)
        Logging.development?.level = .debug

        fakeToggles = MockUserToggles()
        fakePurchases = MockPurchaseValidator()
        permissionChecker = DefaultPermissionChecker() // Change this to a mock
        evaluator = DefaultFeatureConstraintsEvaluator(permissionChecker: permissionChecker, purchaseTracker: fakePurchases, userToggles: fakeToggles)
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
        // At first we don't know
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureA.self), nil)

        // Then we know we don't have it (data loaded)
        fakePurchases.confirmNotPurchased(productA)
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureA.self), false)

        // Then we purchase
        fakePurchases.makeFakePurchase(productA)
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureA.self), true)
    }

    func testAvailabilityOfChildFeatureThatIsUnavailableAndThenPurchased() {
        // At first we don't know
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureB.self), nil)

        // Then we know we don't have it (data loaded)
        fakePurchases.confirmNotPurchased(productB)
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureB.self), false)

        // Then we purchase
        fakePurchases.makeFakePurchase(productB)
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureB.self), true)
    }

    /// Verify that all the conditional features in the ancestry need to be purchased for
    /// the child to be available.
    func testAvailabilityOfChildFeatureWithParentThatIsUnavailableAndThenPurchased() {
        // At first we don't know if the parent is purchased
        XCTAssertEqual(checker.isAvailable(ConditionalParentFeatureA.self), nil)

        // Then we know we don't have it (data loaded)
        fakePurchases.confirmNotPurchased(productC)
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalParentFeatureA.self), false)

        // Then we purchase the parent
        fakePurchases.makeFakePurchase(productC)
        checker.invalidate()
        XCTAssertEqual(checker.isAvailable(ConditionalParentFeatureA.self), true)

        // The child should still not be available, as the child itself has not been purchased
        XCTAssertNotEqual(checker.isAvailable(ConditionalFeatureC.self), true)

        // Purchase the child
        fakePurchases.makeFakePurchase(productD)
        checker.invalidate()

        // The child should now be available
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureC.self), true)
    }
    
    /// Test the some of the permissions adapters
    func testPermissions() {
        print(String(reflecting: permissionChecker!))

        // Check camera permissions
#if targetEnvironment(simulator)
        // On simulator we DO have camera permission initially
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureWithCameraPermissionRequirements.self), nil)
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self), nil)
#else
        // On device we should NOT have camera permission initially
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureWithCameraPermissionRequirements.self), false)
        XCTAssertEqual(checker.isAvailable(ConditionalFeatureWithPhotosAndLocationPermissionRequirements.self), false)
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
        
        requirements.permission(.camera)
    }
    
    public static var enabled = true

    static var description: String = ""
    
    static func prepare(actions: FeatureActionsBuilder) {
    }
}

final private class ConditionalFeatureWithPhotosAndLocationPermissionRequirements: ConditionalFeature {
    static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.precondition(.runtimeEnabled)
        
        requirements.permission(.camera)
        requirements.permission(.location(usage: .whenInUse))
    }

/*
    static func constraints(requirements: FeatureConstraintsBuilder) {
        // ---- Baseline 1 ----
        requirements.precondition(.platform(id: .iOS, version: .atLeast(version: 9)))
        requirements.precondition(.runtimeEnabled)
        requirements.precondition(.userToggled(defultValue: true))
        requirements.precondition(.purchase(requirement: [productA]))

        requirements.permission(.photos)
        requirements.permission(.location(usage: .whenInUse))

        requirements.customPermission(MyPermissions.githubOAuthWriteAccess)

        requirements.appState(.background)
        requirements.appState(.foreground)
        
        requirements.capability(.locationHeadingAvailable)

        requirements.withPlatform(.iOS, version: .atLeast(version: 10)) {
            requirements.capability(.locationSignificantChangeMonitoring)
        }
        
        requirements.withPlatform(.macOS, version: .atLeast(version: "10.12")) {
            requirements.permission(.location(usage: .whenInUse))
        }
        
        // ---- Refinement 1 ----
        requirements.preconditions = [
            .platform(id: .iOS, version: .atLeast(version: 9)),
            .runtimeEnabled,
            .userToggled,
            .purchase(requirement: [productA])
        ]
        
        requirements.permissions = [.photos, .location(usage: .whenInUse)]

        requirements.customPermissioms = [MyPermissions.githubOAuthWriteAccess]

        requirements.appStates = [.background, .foreground]

        requirements.capabilities = [.locationHeadingAvailable]

        requirements.iOS(.atLeast(version: 10)) {
            requirements.capabilities = [.locationSignificantChangeMonitoring]
        }
        
        requirements.macOS(.atLeast(version: "10.12")) {
            requirements.permissions = [.location(usage: .whenInUse)]
        }
        
        // ---- Refinement 2 ----
        requirements.runtimeEnabled()
        requirements.userToggled(defaultValue: true)
        requirements.platform(.iOS, .atLeast(version: 9))
        requirements.purchase(productA)
        
        requirements.photos()
        requirements.location(usage: .whenInUse)

        requirements.customPermissions(MyPermissions.githubOAuthWriteAccess, ...)

        requirements.background()
        requirements.foreground()

        requirements.locationHeadingAvailable()

        requirements.iOS.atLeast(10) {
            requirements.locationSignificantChangeMonitoring()
        }
        
        requirements.macOS.atLeast("10.12") {
            requirements.location(usage: .whenInUse)
        }
    }
 */

    public static var enabled = true

    static var description: String = ""
    
    static func prepare(actions: FeatureActionsBuilder) {
    }
}

