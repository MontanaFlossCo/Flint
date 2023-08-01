//
//  URLMappingRouterTests.swift
//  FlintCore-iOS-Tests
//
//  Created by Alvin Choo on 28/1/19.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import XCTest
@testable import FlintCore

/// Validate that URL mappings route correctly to actions that can be performed
class URLMappingRouterTests: XCTestCase {
    
    fileprivate final class TestFeature: Feature, FeatureGroup, URLMapped {
        static var subfeatures: [FeatureDefinition.Type] = []
        
        static var description: String = "Testing"
        static let testAction = action(TestAction.self)
        static let testAction2 = action(TestAction2.self)
        
        static func prepare(actions: FeatureActionsBuilder) {
            actions.declare(testAction2)
            actions.declare(testAction)
        }
        
        static func urlMappings(routes: URLMappingsBuilder) {
            routes.send("cde", to: testAction2)
            routes.send("abc", to: testAction)
            routes.send("/deeplink1", to: testAction, in: [.universal(domain: "flint.tools")])
        }
    }
    
    fileprivate final class TestAction: FlintUIAction {
        typealias PresenterType = MockViewController
        
        static func perform(context: ActionContext<NoInput>, presenter: MockViewController, completion: Completion) -> Completion.Status {
            
            return completion.completedSync(.successWithFeatureTermination)
        }
    }
    
    fileprivate struct TestInput: RouteParametersDecodable, FlintLoggable {
        
        let value: String?
        
        init?(from routeParameters: RouteParameters?, mapping: URLMapping) {
            
            self.value = routeParameters?["value"]
        }
        
    }
    
    fileprivate final class TestAction2: FlintUIAction {
        typealias PresenterType = UIView
        typealias InputType = TestInput
        
        static func perform(context: ActionContext<TestInput>, presenter: UIView, completion: Completion) -> Completion.Status {
            
            return completion.completedSync(.successWithFeatureTermination)
        }
    }
    
    
    override func setUp() {
        super.setUp()
        Flint.resetForTesting()
    }
    
    func testSuccessRouteAction() {
        Flint.quickSetup(TestFeature.self)
        FlintAppInfo.urlSchemes = ["test"]
        let url = URL(string: "test://abc")!
        
        let presenter = MockPresentationRouter()
        
        RoutesFeature.request(RoutesFeature.performIncomingURL)!.perform(withInput: url,
                                                                         presenter: presenter,
                                                                         completion: { outcome in
                                                                            switch outcome {
                                                                            case .success:
                                                                                XCTAssertTrue(true)
                                                                            default:
                                                                                XCTFail()
                                                                            }
        })
    }
    
    func testSuccessRouteActionWithNoSchemeSlashes() {
        Flint.quickSetup(TestFeature.self)
        FlintAppInfo.urlSchemes = ["test"]
        let url = URL(string: "test:abc")!
        
        let presenter = MockPresentationRouter()
        
        RoutesFeature.request(RoutesFeature.performIncomingURL)!.perform(withInput: url,
                                                                         presenter: presenter,
                                                                         completion: { outcome in
                                                                            switch outcome {
                                                                            case .success:
                                                                                XCTAssertTrue(true)
                                                                            default:
                                                                                XCTFail()
                                                                            }
        })
    }
    
    func testRouteActionWithDeepLinkingDomain() {
        Flint.quickSetup(TestFeature.self)
        FlintAppInfo.associatedDomains = ["flint.tools"]
        
        // Verify mapping success
        let url = URL(string: "https://flint.tools/deeplink1")!
        
        let presenter = MockPresentationRouter()
        
        RoutesFeature.request(RoutesFeature.performIncomingURL)!.perform(withInput: url,
                                                                         presenter: presenter,
                                                                         completion: { outcome in
                                                                            switch outcome {
                                                                            case .success:
                                                                                break
                                                                            default:
                                                                                XCTFail("Expected mapping to succeed")
                                                                            }
        })

        // Verify mapping failure
        let badUrl = URL(string: "https://flint.tools/deepTHISISBADlink1")!
        
        let badPresenter = MockPresentationRouter()
        
        RoutesFeature.request(RoutesFeature.performIncomingURL)!.perform(withInput: badUrl,
                                                                         presenter: badPresenter,
                                                                         completion: { outcome in
                                                                            switch outcome {
                                                                            case .failure:
                                                                                break
                                                                            default:
                                                                                XCTFail("Expected mapping to fail")
                                                                            }
        })

        // Verify mapping failure on invalid domain
        let badUrl2 = URL(string: "https://this.is.not.our.site.com/deeplink1")!
        
        let badPresenter2 = MockPresentationRouter()
        
        RoutesFeature.request(RoutesFeature.performIncomingURL)!.perform(withInput: badUrl2,
                                                                         presenter: badPresenter2,
                                                                         completion: { outcome in
                                                                            switch outcome {
                                                                            case .failure:
                                                                                break
                                                                            default:
                                                                                XCTFail("Expected mapping to fail")
                                                                            }
        })
    }
    
    /// This will work if i register /cde first instead of /abc.
    func testFailureRouteAction() {
        Flint.quickSetup(TestFeature.self)
        FlintAppInfo.urlSchemes = ["test"]
        let url = URL(string: "test://cde")!

        let presenter = MockPresentationRouter()

        RoutesFeature.request(RoutesFeature.performIncomingURL)!.perform(withInput: url,
                                                                         presenter: presenter,
                                                                         completion: { outcome in
                                                                            switch outcome {
                                                                            case .failure:
                                                                                XCTAssertTrue(true)
                                                                            default:
                                                                                XCTFail()
                                                                            }
        })
    }
}
