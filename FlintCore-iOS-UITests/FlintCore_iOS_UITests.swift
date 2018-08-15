//
//  FlintCore_iOS_UITests.swift
//  FlintCore-iOS-UITests
//
//  Created by Marc Palmer on 15/08/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import XCTest
@testable import FlintCore

class FlintCore_iOS_UITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        let _ = addUIInterruptionMonitor(withDescription: "Permission alert silencing") { (alert) in
            alert.buttons["OK"].tap()
            return true // The interruption has been handled
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEventKitAuthorisationRequest() {
        let eventsAdapter = EventKitPermissionAdapter(permission: .calendarEvents)

        let eventsExpectation = expectation(description: "Callback triggered")
        eventsAdapter.requestAuthorisation { adapter, status in
            eventsExpectation.fulfill()
        }
        
        let remindersExpectation = expectation(description: "Callback triggered")
        let remindersAdapter = EventKitPermissionAdapter(permission: .reminders)
        remindersAdapter.requestAuthorisation { adapter, status in
            remindersExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }

    func testContactsAuthorisationRequest() {
        let adapter = ContactsPermissionAdapter(permission: .contacts(entity: .contacts))
        let contactsExpectation = expectation(description: "Callback triggered")

        adapter.requestAuthorisation { adapter, status in
            contactsExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testPhotosAuthorisationRequest() {
        let adapter = PhotosPermissionAdapter(permission: .photos)
        let photosExpectation = expectation(description: "Callback triggered")
        adapter.requestAuthorisation { adapter, status in
            photosExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

}
