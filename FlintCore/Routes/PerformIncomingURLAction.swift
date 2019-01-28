//
//  PerformIncomingURLAction.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 20/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The action that performs an action associated with a given URL.
///
/// Expected input state type: URL
/// Expected presenter type: PresentationRouter
///
/// This will attempt to resolve the URL against the known URL routes defined on `URLMapped` features of the app.
final public class PerformIncomingURLAction: UIAction {
    public typealias InputType = URL
    public typealias PresenterType = PresentationRouter
    
    public static var description: String = "Perform the action associated with the input URL"

    /// The errors possible from performing the action for a given URL mapping
    public enum URLActionError: Error {
        /// There was no action mapped to the URL.
        case noURLMappingFound

        /// The URL was not valid.
        case invalidURL

        /// The URL was mapped to an action but the conditional feature that defines the URL mapping is not currently
        /// available, through permissions, purchase or other feature constraints not being met.
        case notAvailable
        
        /// The PresentationRouter indicated that it does not support routing for the action that the URL is mapped to
        case presenterNotSupported
        
        /// The PresentationRouter indicated that user interaction was required before the UI could transition to the
        /// state required by the action, but the user cancelled this.
        case presenterUserCancelled

        /// The PresentationRouter indicated that a state transition was required for the UI but it was not possible
        /// from the current UI state. This might indicate for example that a modal view controller is currently active.
        case presenterAppCancelled
        
        /// The PresentationRouter indicated that no state transition was required for the UI as the action would result
        /// in the same UI state that is currently being presented.
        case presenterAppPerformed
    }
    
    static private var supportedSchemes: [String] = {
        return FlintAppInfo.urlSchemes
    }()

    static private var supportedDomains: [String] = {
        return FlintAppInfo.associatedDomains
    }()

    /// Attempt to resolve the URL against a URL mapping, and execute the action.
    ///
    /// The completion outcome will fail with error `noURLMappingFound` if the URL does not map to anything
    /// that Flint knows about.
    public static func perform(context: ActionContext<URL>, presenter: PresentationRouter, completion: Action.Completion) -> Action.Completion.Status {
        guard let urlComponents = URLComponents(url: context.input, resolvingAgainstBaseURL: false) else {
            context.logs.development?.error("Invalid URL supplied")
            return completion.completedSync(.failure(error: URLActionError.invalidURL))
        }
        
        // Find a matching mapping.
        var scope: RouteScope?
        var path: String?

        if let scheme = urlComponents.scheme {
            if !["http", "https"].contains(scheme) {
                context.logs.development?.debug("URL is for app scheme: \(scheme)")
                if let _ = supportedSchemes.index(of: scheme) {
                    var compoundPath: String
                    if let host = urlComponents.host {
                        compoundPath = host
                        if urlComponents.path.count > 0 {
                            compoundPath = compoundPath + "\(urlComponents.path)"
                        }
                    } else if urlComponents.path.count > 0 {
                        compoundPath = urlComponents.path
                    } else {
                        return completion.completedSync(.failure(error: URLActionError.invalidURL))
                    }
                    
                    scope = .app(scheme: scheme)
                    path = compoundPath
                }
            } else {
                if let domain = urlComponents.host,
                        let _ = supportedDomains.index(of: domain) {
                    context.logs.development?.debug("URL is for domain: \(domain)")
                    scope = .universal(domain: domain)
                    path = urlComponents.path
                }
            }
        }

        guard let foundScope = scope, let foundPath = path else {
            context.logs.development?.error("Couldn't map URL: \(context.input)")
            return completion.completedSync(.failureWithFeatureTermination(error: URLActionError.noURLMappingFound))
        }

        context.logs.development?.debug("Finding action executor for scope: \(foundScope), path \(foundPath)")
        
        if let executionContext = ActionURLMappings.instance.actionExecutionContext(for: foundPath, in: foundScope) {
            var queryParameters = [String:String]()
            // Copy over the query parameters
            if let queryItems = urlComponents.queryItems {
                for item in queryItems {
                    queryParameters[item.name] = item.value
                }
            }
            
            // We make sure parameters set by the URL path macros win over query parameters.
            if let parsedParams = executionContext.parsedParameters {
                queryParameters.merge(parsedParams) { (oldValue, newValue) -> String in
                    return newValue
                }
            }
            
            let params: RouteParameters = queryParameters

            context.logs.development?.debug("Executing action with query params: \(String(describing: params))")

            var result: Action.Completion.Status!
            executionContext.executor(params, presenter, context.source) { outcome in
                result = completion.completedSync(outcome)
            }
            flintUsagePrecondition(result != nil, "Currently actions performed by URL must complete synchronously")
            return result
        } else {
            context.logs.development?.error("Couldn't get executor for URL: \(context.input) for scope \(foundScope) and path \(foundPath)")
            return completion.completedSync(.failureWithFeatureTermination(error: URLActionError.noURLMappingFound))
        }
        
    }
}

