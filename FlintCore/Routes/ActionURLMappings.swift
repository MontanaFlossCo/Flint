//
//  ActionURLMappings.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This type stores the URL mappings to features and actions, as defined in the routes specified in `URLMapped`
/// Feature definitions.
///
/// It is used to add mappings and retrieve them later when a URL is received and there is a need to resolve that
/// to an Action if possible.
class ActionURLMappings {
    /// Callback function used to invoke an action for a URL
    typealias URLExecutor = (_ queryParams: RouteParameters?, _ PresentationRouter: PresentationRouter, _ source: ActionSource, _ completion: (ActionPerformOutcome) -> Void) -> ()
    
    /// Global internal var for all the app's mappings
    static var instance = ActionURLMappings()

    /// Used to generate links TO: feature+actions
    var urlMappingsByFeatureAndActionName: [String:[URLMapping]] = [:]

    /// Used to executue actions for incoming links
    var executorsByUrlMapping: [URLMapping:URLExecutor] = [:]

    /// Add a URL Mapping, with the `URLExecutor` used to actually invoke the action.
    /// - note: This mechanism is required because of the associate type requiremets on `Action`
    func add(mapping: URLMapping, for feature: FeatureDefinition.Type, actionName: String, executor: @escaping URLExecutor) {
        let compoundStringKey = featureActionKey(for: feature, action: actionName)
        var mappingsForAction = urlMappingsByFeatureAndActionName[compoundStringKey] ?? []
        mappingsForAction.append(mapping)
        urlMappingsByFeatureAndActionName[compoundStringKey] = mappingsForAction
        executorsByUrlMapping[mapping] = executor
    }

    /// Retrieves the action executor block, if any, for the given URL path in the specified Route scope.
    /// The executor captures the original generic Action so that it can be stored here and executed later even though
    /// `Action` has associated types.
    func actionExecutor(for path: String, in scope: RouteScope) -> URLExecutor? {
        guard ![RouteScope.appAny, RouteScope.universalAny].contains(scope) else {
            preconditionFailure("Cannot resolve an action executor for non-specific scopes.")
        }

        let matchingResult = findMatchingURLPattern(for: path, in: scope)
        if case let .match(mapping, params) = matchingResult {
            if let executor = executorsByUrlMapping[mapping] {
                return executor
            }
        } else {
            // There was no specific mapping, is there an Any mapping?
            let wildcardScope: RouteScope
            switch scope {
                case .app: wildcardScope = .appAny
                case .universal: wildcardScope = .universalAny
                default:
                    fatalError("Incorrect scope logic")
            }

            let matchingResult = findMatchingURLPattern(for: path, in: wildcardScope)
            if case let .match(mapping, params) = matchingResult {
                if let executor = executorsByUrlMapping[mapping] {
                    return executor
                }
            }
            return nil
        }
    }

    func findMatchingURLPattern(for path: String, in scope: RouteScope) -> URLMappingResult {
        let allMappings = urlMappingsByFeatureAndActionName.values.flatMap { $0 }
        for mapping in allMappings {
            if scope == mapping.scope {
                let matchResult = mapping.matches(path: path)
                if case .match = matchResult {
                    return matchResult
                }
            }
        }
        return .noMatch
    }

    /// Retrieve all the url mappings defined for the specified feature and action combination.
    func mappings(for feature: FeatureDefinition.Type, action actionName: String) -> [URLMapping]? {
        let key = featureActionKey(for: feature, action: actionName)
        return urlMappingsByFeatureAndActionName[key]
    }
    
    private func featureActionKey(for feature: FeatureDefinition.Type, action actionName: String) -> String {
        let featureName = String(describing: feature.name)
        return "\(featureName)#\(actionName)"
    }
}
