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
            builder.platform(.init(platform: .iOS, version: .any))
            builder.platform(.init(platform: .macOS, version: "10.13"))
            builder.platform(.init(platform: .tvOS, version: 11))
            builder.platform(.init(platform: .watchOS, version: .any))
        }
     
        func _assertContains(_ id: Platform, _ version: PlatformVersionConstraint) {
            XCTAssertTrue(constraints.allDeclaredPlatforms[id] == PlatformConstraint(platform: id, version: version),
                          "Expected to find \(id) with \(version) but didn't")
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
            XCTAssertTrue(constraints.allDeclaredPlatforms[id] == PlatformConstraint(platform: id, version: version),
                          "Expected to find \(id) with \(version) but didn't")
        }

        _assertContains(.iOS, .atLeast(version: 11))
        _assertContains(.macOS, .atLeast(version: OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0)))
        _assertContains(.tvOS, .atLeast(version: 10))
        _assertContains(.watchOS, .any)
    }

    func testAnyPlatformVersionsAreDefault() {
    
        let constraints = evaluate { builder in
            // Nothing, default is specified as .any
        }
     
        func _assertContains(_ id: Platform, _ version: PlatformVersionConstraint) {
            XCTAssertTrue(constraints.allDeclaredPlatforms[id] == PlatformConstraint(platform: id, version: version),
                          "Expected to find \(id) with \(version) but didn't")
        }

        _assertContains(.iOS, .any)
        _assertContains(.macOS, .any)
        _assertContains(.tvOS, .any)
        _assertContains(.watchOS, .any)
    }

    func testAtLeastIntPlatformVersionsProperties() {
    
        let constraints = evaluate { builder in
            builder.iOS = 10
            builder.macOS = 10
            builder.tvOS = 11
            builder.watchOS = 4
        }
     
        func _assertContains(_ id: Platform, _ version: PlatformVersionConstraint) {
            XCTAssertTrue(constraints.allDeclaredPlatforms[id] == PlatformConstraint(platform: id, version: version),
                          "Expected to find \(id) with \(version) but didn't")
        }

        _assertContains(.iOS, .atLeast(version: 10))
        _assertContains(.macOS, .atLeast(version: 10))
        _assertContains(.tvOS, .atLeast(version: 11))
        _assertContains(.watchOS, .atLeast(version: 4))
    }

    func testAtLeastStringPlatformVersionsProperties() {
    
        let constraints = evaluate { builder in
            builder.iOS = "10.1"
            builder.macOS = "10.13"
            builder.tvOS = "11.2"
            builder.watchOS = "4.1"
        }
     
        func _assertContains(_ id: Platform, _ version: PlatformVersionConstraint) {
            XCTAssertTrue(constraints.allDeclaredPlatforms[id] == PlatformConstraint(platform: id, version: version),
                          "Expected to find \(id) with \(version) but didn't")
        }

        _assertContains(.iOS, .atLeast(version: OperatingSystemVersion(majorVersion: 10, minorVersion: 1, patchVersion: 0)))
        _assertContains(.macOS, .atLeast(version: OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0)))
        _assertContains(.tvOS, .atLeast(version: OperatingSystemVersion(majorVersion: 11, minorVersion: 2, patchVersion: 0)))
        _assertContains(.watchOS, .atLeast(version: OperatingSystemVersion(majorVersion: 4, minorVersion: 1, patchVersion: 0)))
    }
}
