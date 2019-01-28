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

    public enum URLActionError: Error {
        case noURLMappingFound
        case invalidURL
        case featureNotAvailable
        case featureUnsupported
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
                    guard let host = urlComponents.host else {
                        return completion.completedSync(.failure(error: URLActionError.invalidURL))
                    }
                    var compoundPath = host
                    if urlComponents.path.count > 0 {
                        compoundPath = compoundPath + "\(urlComponents.path)"
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

