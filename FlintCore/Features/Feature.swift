//
//  Feature.swift
//  FlintCore
//
//  Created by Marc Palmer on 21/12/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Classes conforming to Feature represent an always-available feature that can perform actions.
///
/// To define such a feature, conform to this protocol and declare static properties for the
/// actions it supports, using the `action(Action.Type)` helper function. You then override `prepare` and
/// use the actions builder to declare or publish those actions:
///
/// ```
/// class DocumentManagementFeature: Feature, URLMapped {
///     static let description = "Create, Open and Save documents"
///
///     static let createNew = action(DocumentCreateAction.self)
///     static let openDocument = action(DocumentOpenAction.self)
///     static let closeDocument = action(DocumentCloseAction.self)
///     static let saveDocument = action(DocumentSaveAction.self)
///
///     static func prepare(actions: FeatureActionsBuilder) {
///         actions.declare(createNew)
///         actions.declare(openDocument)
///         actions.declare(closeDocument)
///         actions.declare(saveDocument)
///     }
///
///     static func urlMappings(routes: URLMappingsBuilder) {
///         routes.send("create", to: createNew)
///         routes.send("open", to: openDocument)
///     }
/// }
/// ```
///
/// You can optionally override the default implementations of `name` and `description` of you want to change how the
/// feature is presented in logging and debug UI.
///
/// -note: This type exists simply to allow protocol extenions on this type that are not to be inherited by
/// `ConditionalFeatureDefinition`, e.g. the differing `action()` binding functions.
///
/// - see: `ConditionalFeature` for features that can be enabled or disabled based on some condition.
public protocol Feature: FeatureDefinition {
}

/// Default implementations and helper functions for action binding and convenience functions
/// for performing actions in the main session.
public extension Feature {

    /// Function for binding a feature and action pair, to restrict how this can be done externally by app code.
    public static func action<ActionType>(_ action: ActionType.Type) -> StaticActionBinding<Self, ActionType> {
        return StaticActionBinding(feature: self, action: action)
    }

    /// Function for binding a feature and action pair, to restrict how this can be done externally by app code.
#if canImport(Intents) && os(iOS)
    @available(iOS 12, *)
    public static func action<ActionType>(_ action: ActionType.Type) -> StaticActionBinding<Self, ActionType> where ActionType: IntentAction {
        return StaticActionBinding(feature: self, action: action)
    }
#endif
}
