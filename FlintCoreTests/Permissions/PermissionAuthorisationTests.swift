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

    /// Verify that checking authorisation status works. This can fail if using dynamic lookups and selectors are wrong.
    ///
    /// - note: This requires the test host app to link against EventKit
    func testEventKitAuthorisationStatus() {
        let eventsAdapter = EventKitPermissionAdapter(permission: .calendarEvents)
        let _ = eventsAdapter.status
        let remindersAdapter = EventKitPermissionAdapter(permission: .reminders)
        let _ = remindersAdapter.status
    }

    func testEventKitAuthorisationRequest() {
        let eventsAdapter = EventKitPermissionAdapter(permission: .calendarEvents)
        eventsAdapter.requestAuthorisation { adapter, status in
        }
        let remindersAdapter = EventKitPermissionAdapter(permission: .reminders)
        remindersAdapter.requestAuthorisation { adapter, status in
        }
    }

    func testContactsAuthorisationStatus() {
        let adapter = ContactsPermissionAdapter(permission: .contacts(entity: .contacts))
        let _ = adapter.status
    }

    func testContactsAuthorisationRequest() {
        let adapter = ContactsPermissionAdapter(permission: .contacts(entity: .contacts))
        adapter.requestAuthorisation { adapter, status in
        }
    }

    func testPhotosAuthorisationStatus() {
        let adapter = PhotosPermissionAdapter(permission: .photos)
        let _ = adapter.status
    }

    func testPhotosAuthorisationRequest() {
        let adapter = PhotosPermissionAdapter(permission: .photos)
        adapter.requestAuthorisation { adapter, status in
        }
    }
}
