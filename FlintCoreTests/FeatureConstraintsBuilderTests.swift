//
//  FeatureConstraintsBuilderTests.swift
//  FlintCore
//
//  Created by Marc Palmer on 02/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import XCTest
@testable import FlintCore

/// These tests attempt to unit test the DefaultAvailabilityChecker.
///
/// To do this we don't want to bootstrap Flint itself, so we have to manually set up the environment
/// and evaluate the constraints on our test features.
class FeatureConstraintsBuilderTests: XCTestCase {
 
    var checker: AvailabilityChecker!
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func evaluate(constraints: (FeatureConstraintsBuilder) -> Void) -> FeatureConstraints {
        let builder = DefaultFeatureConstraintsBuilder()
        return builder.build(constraints)
    }

    func testPlatformVersionsAdditive() {
    
        let constraints = evaluate { builder in
            builder.preconditions(.iOS)
            builder.precondition(.macOS("10.13"))
            builder.precondition(.tvOS(11))
            builder.precondition(.watchOS(.any))
        }
     
        func _assertContains(_ id: Platform, _ version: PlatformVersionConstraint) {
            XCTAssertTrue(constraints.preconditions.contains(.platform(id: id, version: version)), "Expected to find \(id) with \(version) but didn't")
        }

        _assertContains(.iOS, .any)
        _assertContains(.macOS, .atLeast(version: OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0)))
        _assertContains(.tvOS, .atLeast(version: 11))
        _assertContains(.watchOS, .any)
    }

    func testPlatformVersionAssignment() {
    
        let constraints = evaluate { builder in
            builder.iOS = 11
            builder.macOS = "10.13"
            builder.tvOS = 10
            builder.watchOS = .any
        }
     
        func _assertContains(_ id: Platform, _ version: PlatformVersionConstraint) {
            XCTAssertTrue(constraints.preconditions.contains(.platform(id: id, version: version)), "Expected to find \(id) with \(version) but didn't")
        }

        _assertContains(.iOS, .atLeast(version: 11))
        _assertContains(.macOS, .atLeast(version: OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0)))
        _assertContains(.tvOS, .atLeast(version: 10))
        _assertContains(.watchOS, .any)
    }

    func testAnyPlatformVersions() {
    
        let constraints = evaluate { builder in
            builder.preconditions(.iOS, .macOS, .tvOS, .watchOS)
        }
     
        func _assertContains(_ id: Platform, _ version: PlatformVersionConstraint) {
            XCTAssertTrue(constraints.preconditions.contains(.platform(id: id, version: version)))
        }

        _assertContains(.iOS, .any)
        _assertContains(.macOS, .any)
        _assertContains(.tvOS, .any)
        _assertContains(.watchOS, .any)
    }

    func testAtLeastIntPlatformVersions() {
    
        let constraints = evaluate { builder in
            builder.preconditions(.iOS(10), .macOS(13), .tvOS(11), .watchOS(9))
        }
     
        func _assertContains(_ id: Platform, _ version: PlatformVersionConstraint) {
            XCTAssertTrue(constraints.preconditions.contains(.platform(id: id, version: version)))
        }

        _assertContains(.iOS, .atLeast(version: 10))
        _assertContains(.macOS, .atLeast(version: 13))
        _assertContains(.tvOS, .atLeast(version: 11))
        _assertContains(.watchOS, .atLeast(version: 9))
    }
}
