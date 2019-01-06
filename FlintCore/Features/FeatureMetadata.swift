//
//  FeatureMetadata.swift
//  FlintCore
//
//  Created by Marc Palmer on 18/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Metadata describing a single feature.
///
/// The `Flint` object makes this metadata available for runtime examination of the Features and actions available.
///
/// The FlintUI `FeatureBrowserFeature` takes advantage of this to provide a hierarchical UI to look at the
/// graph of features and actions defined in the app.
public class FeatureMetadata: Hashable, Equatable {
    public let hashValue: Int
    public let feature: FeatureDefinition.Type

    public private(set) var actions = [ActionMetadata]()
    public private(set) var publishedActions = [ActionMetadata]()

    init(feature: FeatureDefinition.Type) {
        self.feature = feature
        hashValue = String(describing: feature).hashValue
    }
    
    func bind<T>(_ action: T.Type) where T: Action {
        _bind(action, publish: false)
    }

    func hasDeclaredAction<T>(_ action: T.Type) -> Bool where T: Action {
        return actions.contains { $0.typeName == String(reflecting: action) }
    }

    func publish<T>(_ action: T.Type) where T: Action {
        _bind(action, publish: true)
    }

    func setActionURLMappings(_ mappings: URLMappings) {
        for (actionTypeName, mapping) in mappings.mappings {
            let firstFound = actions.first { return $0.typeName == actionTypeName }
            guard let action = firstFound else {
                flintUsageError("Cannot find action metadata for action \(actionTypeName) for the URL mapping \(mapping). Did you forget to declare or publish the action?")
            }
            action.add(urlMapping: mapping)
        }
    }
    
    func setIntentMappings(_ mappings: IntentMappings) {
        for (intentTypeName, mapping) in mappings.mappings {
            let firstFound = actions.first { return $0.typeName == mapping.actionTypeName }
            guard let action = firstFound else {
                flintUsageError("Cannot find metadata for action \(mapping.actionTypeName) for the Intent type \(intentTypeName). Did you forget to declare or publish the action?")
            }
            action.add(intentMapping: mapping)
        }
    }
    
    func _bind<T>(_ action: T.Type, publish: Bool) where T: Action {
        let existingAction = actions.first {
            return $0.typeName == String(reflecting: action)
        }
        guard nil == existingAction else {
            return
        }
        let actionMetadata = ActionMetadata(action)
        actions.append(actionMetadata)
        if publish {
            publishedActions.append(actionMetadata)
        }
    }

    public static func ==(lhs: FeatureMetadata, rhs: FeatureMetadata) -> Bool {
        return lhs.feature == rhs.feature
    }
}
