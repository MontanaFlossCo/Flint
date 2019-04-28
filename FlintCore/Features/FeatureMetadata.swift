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
public class FeatureMetadata: Hashable {
    public let feature: FeatureDefinition.Type

    public private(set) var actions = [ActionMetadata]()
    public private(set) var publishedActions = [ActionMetadata]()
    public internal(set) var productsRequired = Set<Product>()

    private let _hashValue: Int

#if swift(<4.2)
    public var hashValue: Int {
        return _hashValue
    }
#else
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_hashValue)
    }
#endif

    init(feature: FeatureDefinition.Type) {
        self.feature = feature
        _hashValue = String(describing: feature).hashValue
    }
    
    public func actionMetadata<ActionType>(action: ActionType.Type) -> ActionMetadata? {
        let typeName = String(reflecting: action)
        return actions.first { $0.typeName == typeName }
    }
    
    func bind<T>(_ action: T.Type) where T: Action {
        _bind(action, publish: false)
    }

    func publish<T>(_ action: T.Type) where T: Action {
        _bind(action, publish: true)
    }

#if canImport(Intents) && os(iOS)
    @available(iOS 12, *)
    func bind<T>(_ action: T.Type) where T: IntentAction {
        _bind(action, publish: false)
    }

    @available(iOS 12, *)
    func publish<T>(_ action: T.Type) where T: IntentAction {
        _bind(action, publish: true)
    }

    @available(iOS 12, *)
    private func _bind<ActionType>(_ action: ActionType.Type, publish: Bool) where ActionType: IntentAction {
        let metadata = _bindInternal(action, publish: publish)
        metadata.setIntent(ActionType.IntentType.self)
    }
#endif

    func hasDeclaredAction<T>(_ action: T.Type) -> Bool where T: Action {
        return actions.contains { $0.typeName == String(reflecting: action) }
    }

    func setActionURLMappings(_ mappings: URLMappings) {
        for (urlActionNamePair, mapping) in mappings.mappings {
            let (_, actionTypeName) = urlActionNamePair
            let firstFound = actions.first { return $0.typeName == actionTypeName }
            guard let action = firstFound else {
                flintUsageError("Cannot find action metadata for action \(actionTypeName) for the URL mapping \(mapping). Did you forget to declare or publish the action?")
            }
            action.add(urlMapping: mapping)
        }
    }

    private func _bind<ActionType>(_ action: ActionType.Type, publish: Bool) where ActionType: Action {
        let _ = _bindInternal(action, publish: publish)
    }
    
    private func _bindInternal<ActionType>(_ action: ActionType.Type, publish: Bool) -> ActionMetadata where ActionType: Action {
        let existingAction = actions.first {
            return $0.typeName == String(reflecting: action)
        }
        guard nil == existingAction else {
            flintUsageError("Actions cannot be bound to the same feature multiple times: \(ActionType.self)")
        }
        let actionMetadata = ActionMetadata(action)
        actions.append(actionMetadata)
        if publish {
            publishedActions.append(actionMetadata)
        }
        return actionMetadata
    }
    
    public static func ==(lhs: FeatureMetadata, rhs: FeatureMetadata) -> Bool {
        return lhs.feature == rhs.feature
    }
}
