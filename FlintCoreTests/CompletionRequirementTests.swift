//
//  CompletionRequirementTests.swift
//  FlintCore
//
//  Created by Marc Palmer on 19/08/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import XCTest
import FlintCore

/// Test the `CompletionRequirement` type
class CompletionRequirementTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testSynchronousCompletion() {
        typealias Completion = CompletionRequirement<String>
        
        let completionExpectation = expectation(description: "Completion called")

        // Pretend we are in some kind of action
        func _findAwesomeAlbumTitle(completion: Completion) -> Completion.Status {
            return completion.completedSync("Voices")
        }
        
        let completion = Completion(completionHandler: { item, completedAsync in
            completionExpectation.fulfill()
            
            XCTAssertFalse(completedAsync, "Sync completion should have completedAsync == false")
        })
        
        let result = _findAwesomeAlbumTitle(completion: completion)
        
        waitForExpectations(timeout: 1.0)
        
        XCTAssertTrue(completion.verify(result), "Status must be from the completion instance we created")
        XCTAssertFalse(result.isCompletingAsync, "Status must be for sync execution")
    }

    func testAsynchronousCompletion() {
        typealias Completion = CompletionRequirement<String>
        
        let completionExpectation = expectation(description: "Completion called")

        // Pretend we are in some kind of action
        func _findAwesomeArtist(completion: Completion) -> Completion.Status {
            let result = completion.willCompleteAsync()
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1, execute: {
                result.completed("Wormrot")
            })
            return result
        }
        
        let completion = Completion(completionHandler: { item, completedAsync in
            completionExpectation.fulfill()
            
            XCTAssertTrue(completedAsync, "Acync completion should have completedAsync == true")
        })
        
        let result = _findAwesomeArtist(completion: completion)
        
        waitForExpectations(timeout: 2.0)
        
        XCTAssertTrue(completion.verify(result), "Status must be from the completion instance we created")
        XCTAssertTrue(result.isCompletingAsync, "Status must be for async execution")
    }

    /// Test the case where we know that we are going to complete sync, and we're calling something else we know
    /// will be sync.
    ///
    /// This demonstrates that synchronous co-dependent completion requirements to not need any special treatment.
    func testSynchronousCompletionFromSynchronousCompletion() {
        typealias TitleCompletion = CompletionRequirement<String>
        typealias AlbumCompletion = CompletionRequirement<Dictionary<String, String>>

        let completionExpectation = expectation(description: "Completion called")

        // Pretend we are in some kind of action
        func _findAlbum(completion: AlbumCompletion) -> AlbumCompletion.Status {
            return completion.completedSync(["title":"Voices"])
        }
        func _findAwesomeAlbumTitle(completion: TitleCompletion) -> TitleCompletion.Status {
            var title: String!
            
            let albumCompletion = AlbumCompletion(completionHandler: { (album, completedAsync) in
                XCTAssertEqual(album["title"], "Voices", "Album title is incorrect")
                title = album["title"]
            })
            let albumResult = _findAlbum(completion: albumCompletion)
            XCTAssertTrue(albumCompletion.verify(albumResult), "Status must be from the album completion instance we created")
            XCTAssertFalse(albumResult.isCompletingAsync, "Status must be for sync execution")

            return completion.completedSync(title)
        }
        
        let completion = TitleCompletion(completionHandler: { title, completedAsync in
            completionExpectation.fulfill()
            
            XCTAssertFalse(completedAsync, "Sync completion should have completedAsync == false")
            XCTAssertEqual("Voices", title, "Title is incorrect")
        })
        
        let result = _findAwesomeAlbumTitle(completion: completion)
        
        waitForExpectations(timeout: 1.0)
        
        XCTAssertTrue(completion.verify(result), "Status must be from the completion instance we created")
        XCTAssertFalse(result.isCompletingAsync, "Status must be for sync execution")
    }

    /// Test the case where we know that we are going to complete async, and we're calling something else we know
    /// will be async.
    ///
    /// This demonstrates the pattern of capturing the async DeferredResult first, so that the completion block
    /// can be used to reference it and call completion.
    ///
    /// If you don't know whether the completion will be called async or not,this pattern does not work and
    /// you have to use `ProxyCompletionRequirement`.
    func testAsynchronousCompletionFromAsynchronousCompletion() {
        typealias TitleCompletion = CompletionRequirement<String>
        typealias AlbumCompletion = CompletionRequirement<Dictionary<String, String>>

        let titleCompletionExpectation = expectation(description: "Title completion called")
        let albumCompletionExpectation = expectation(description: "Album completion called")

        // Pretend we are in some kind of action
        func _findAlbum(completion: AlbumCompletion) -> AlbumCompletion.Status {
            let result = completion.willCompleteAsync()
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1, execute: {
                result.completed(["title":"Voices"])
            })
            return result
        }
        
        func _findAwesomeAlbumTitle(completion: TitleCompletion) -> TitleCompletion.Status {
            let albumTitleResult = completion.willCompleteAsync()

            // Do an async fetch of this info
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1, execute: {
                let albumCompletion = AlbumCompletion(completionHandler: { (album, completedAsync) in
                    let title = album["title"]!
                    albumTitleResult.completed(title)
                })

                let albumResult = _findAlbum(completion: albumCompletion)
                XCTAssertTrue(albumCompletion.verify(albumResult), "Status must be from the album completion instance we created")
                XCTAssertTrue(albumResult.isCompletingAsync, "Status must be for async execution")

                albumCompletionExpectation.fulfill()
            })

            return albumTitleResult
        }
        
        let completion = TitleCompletion(completionHandler: { title, completedAsync in
            titleCompletionExpectation.fulfill()
            XCTAssertTrue(completedAsync, "Sync completion should have completedAsync == false")
            XCTAssertEqual("Voices", title, "Title is incorrect")
        })
        
        let result = _findAwesomeAlbumTitle(completion: completion)
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertTrue(completion.verify(result), "Status must be from the completion instance we created")
        XCTAssertTrue(result.isCompletingAsync, "Status must be for async execution")
    }

    /// If you are in a function that requires completion, and need to call another function that requires completion,
    /// with the option to modify the final result returned from the nested completion, you use `ProxyCompletionRequirement`
    func testProxyCompletion() {
        typealias TitleCompletion = CompletionRequirement<String>
        typealias AlbumCompletion = CompletionRequirement<Dictionary<String, String>>

        let titleCompletionExpectation = expectation(description: "Title completion called")
        let albumCompletionExpectation = expectation(description: "Album completion called")

        // Pretend we are in some kind of action
        func _findAlbum(completion: AlbumCompletion) -> AlbumCompletion.Status {
            let result = completion.willCompleteAsync()
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1, execute: {
                result.completed(["title":"Voices"])
            })
            return result
        }
        
        func _findAwesomeAlbumTitle(completion: TitleCompletion) -> TitleCompletion.Status {
            let albumTitleResult = completion.willCompleteAsync()

            // Do an async fetch of this info
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1, execute: {
                let albumCompletion = AlbumCompletion(completionHandler: { (album, completedAsync) in
                    let title = album["title"]!
                    albumTitleResult.completed(title)
                })

                let albumResult = _findAlbum(completion: albumCompletion)
                XCTAssertTrue(albumCompletion.verify(albumResult), "Status must be from the album completion instance we created")
                XCTAssertTrue(albumResult.isCompletingAsync, "Status must be for async execution")

                albumCompletionExpectation.fulfill()
            })

            return albumTitleResult
        }
        
        /// This is the completion that we will proxy. It in turn relies on another async completion
        let completion = TitleCompletion(completionHandler: { title, completedAsync in
            titleCompletionExpectation.fulfill()
            XCTAssertTrue(completedAsync, "Sync completion should have completedAsync == false")
            XCTAssertEqual("Title: Voices", title, "Title is incorrect")
        })
        
        // We'll proxy the real title completion, to add a prefix
        let proxyCompletion = ProxyCompletionRequirement<String>(proxying: completion) { title, wasAsync -> String in
            return "Title: \(title)"
        }
        
        let result = _findAwesomeAlbumTitle(completion: proxyCompletion)
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertTrue(proxyCompletion.verify(result), "Status must be from the proxy completion instance we created")
        XCTAssertTrue(result.isCompletingAsync, "Status must be for async execution")
    }

}
