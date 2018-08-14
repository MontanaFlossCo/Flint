//
//  PermissionAuthorisationTests.swift
//  FlintCore
//
//  Created by Marc Palmer on 14/08/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import XCTest
@testable import FlintCore

class PermissionAuthorisationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testEventKitAuthorisationSelector() {
        let adapter = EventKitPermissionAdapter(permission: .calendarEvents)
        let _ = adapter.status
    }
}
