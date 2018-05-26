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

    // MARK: Helpers
    
    func evaluate(constraints: (FeatureConstraintsBuilder) -> Void) -> DeclaredFeatureConstraints {
        let builder = DefaultFeatureConstraintsBuilder()
        return builder.build(constraints)
    }

    func _assertContains(_ constraints: DeclaredFeatureConstraints, _ id: Platform, _ version: PlatformVersionConstraint) {
        XCTAssertTrue(constraints.allDeclaredPlatforms[id] == PlatformConstraint(platform: id, version: version),
                      "Expected to find \(id) with \(version) but didn't")
    }

    // MARK: Tests
    
    func testPlatformVersionsAdditive() {
    
        let constraints = evaluate { builder in
            builder.platform(.init(platform: .iOS, version: .any))
            builder.platform(.init(platform: .macOS, version: "10.13"))
            builder.platform(.init(platform: .tvOS, version: 11))
            builder.platform(.init(platform: .watchOS, version: .any))
        }
     
        _assertContains(constraints, .iOS, .any)
        _assertContains(constraints, .macOS, .atLeast(version: OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0)))
        _assertContains(constraints, .tvOS, .atLeast(version: 11))
        _assertContains(constraints, .watchOS, .any)
    }

    func testPlatformVersionAssignment() {
    
        let constraints = evaluate { builder in
            builder.iOS = 11
            builder.macOS = "10.13"
            builder.tvOS = 10
            builder.watchOS = .any
        }
     
        _assertContains(constraints, .iOS, .atLeast(version: 11))
        _assertContains(constraints, .macOS, .atLeast(version: OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0)))
        _assertContains(constraints, .tvOS, .atLeast(version: 10))
        _assertContains(constraints, .watchOS, .any)
    }

    func testAnyPlatformVersionsAreDefault() {
    
        let constraints = evaluate { builder in
            // Nothing, default is specified as .any
        }
     
        _assertContains(constraints, .iOS, .any)
        _assertContains(constraints, .macOS, .any)
        _assertContains(constraints, .tvOS, .any)
        _assertContains(constraints, .watchOS, .any)
    }

    func testAtLeastIntPlatformVersionsProperties() {
    
        let constraints = evaluate { builder in
            builder.iOS = 10
            builder.macOS = 10
            builder.tvOS = 11
            builder.watchOS = 4
        }
     
        _assertContains(constraints, .iOS, .atLeast(version: 10))
        _assertContains(constraints, .macOS, .atLeast(version: 10))
        _assertContains(constraints, .tvOS, .atLeast(version: 11))
        _assertContains(constraints, .watchOS, .atLeast(version: 4))
    }

    func testAtLeastStringPlatformVersionsProperties() {
    
        let constraints = evaluate { builder in
            builder.iOS = "10.1"
            builder.macOS = "10.13"
            builder.tvOS = "11.2"
            builder.watchOS = "4.1"
        }

        _assertContains(constraints, .iOS, .atLeast(version: OperatingSystemVersion(majorVersion: 10, minorVersion: 1, patchVersion: 0)))
        _assertContains(constraints, .macOS, .atLeast(version: OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0)))
        _assertContains(constraints, .tvOS, .atLeast(version: OperatingSystemVersion(majorVersion: 11, minorVersion: 2, patchVersion: 0)))
        _assertContains(constraints, .watchOS, .atLeast(version: OperatingSystemVersion(majorVersion: 4, minorVersion: 1, patchVersion: 0)))
    }

    func testXXXOnly() {
    
        let constraintsiOS = evaluate { builder in
            builder.macOS = "10.13"
            builder.tvOS = "11.2"
            builder.watchOS = "4.1"
            builder.iOSOnly = 9
        }
     
        _assertContains(constraintsiOS, .iOS, .atLeast(version: OperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0)))
        _assertContains(constraintsiOS, .macOS, .unsupported)
        _assertContains(constraintsiOS, .tvOS, .unsupported)
        _assertContains(constraintsiOS, .watchOS, .unsupported)

        let constraintsMacOS = evaluate { builder in
            builder.tvOS = "11.2"
            builder.watchOS = "4.1"
            builder.iOS = 9
            builder.macOSOnly = "10.13"
        }
     
        _assertContains(constraintsMacOS, .iOS, .unsupported)
        _assertContains(constraintsMacOS, .macOS, .atLeast(version: OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0)))
        _assertContains(constraintsMacOS, .tvOS, .unsupported)
        _assertContains(constraintsMacOS, .watchOS, .unsupported)

        let constraintsWatchOS = evaluate { builder in
            builder.tvOS = "11.2"
            builder.iOS = 9
            builder.macOS = "10.13"
            builder.watchOSOnly = "4.1"
        }
     
        _assertContains(constraintsWatchOS, .iOS, .unsupported)
        _assertContains(constraintsWatchOS, .macOS, .unsupported)
        _assertContains(constraintsWatchOS, .tvOS, .unsupported)
        _assertContains(constraintsWatchOS, .watchOS, .atLeast(version: OperatingSystemVersion(majorVersion: 4, minorVersion: 1, patchVersion: 0)))

        let constraintsTVOS = evaluate { builder in
            builder.iOS = 9
            builder.macOS = "10.13"
            builder.watchOS = "4.1"
            builder.tvOSOnly = "11.2"
        }
     
        _assertContains(constraintsTVOS, .iOS, .unsupported)
        _assertContains(constraintsTVOS, .macOS, .unsupported)
        _assertContains(constraintsTVOS, .tvOS, .atLeast(version: OperatingSystemVersion(majorVersion: 11, minorVersion: 2, patchVersion: 0)))
        _assertContains(constraintsTVOS, .watchOS, .unsupported)
    }
}
