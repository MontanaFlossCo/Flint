//
//  FocusSeleection.swift
//  FlintCore
//
//  Created by Marc Palmer on 06/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// An implementation of `FocusSelection` is used to control what logging and debug info is currently being
/// produced. When the focus selection is empty (reset), all the normal logging levels apply and there is
/// no filtering.
///
/// Focusing on one or more features results in only logging related to the focused items being produced,
/// automatically setting debug log level for those features and topic paths.
///
/// Topic Paths are used to allow control of non-Feature subsystems that have opted in to Contextual Logging.
/// Feature identifiers are converted to Topic Paths so we have one common concept for logging hierarchy.
///
/// - see: `TopicPath`
public protocol FocusSelection {

    /// This is set to `true` if there is currently a non-empty focus selection, i.e. focus is being used.
    /// When `false` this means all debug output should be included
    var isActive: Bool { get }
    
    /// Test if something should be suppressed from output. This exists so that we can easily write:
    ///
    /// `guard !FlintInternal.focusSelection?.shouldSuppress(x) == true else { return }`
    ///
    /// This way, if the selection is nil OR `x` is not in the focus selection, we can get out concisely.
    ///
    /// - return: `true` if the specific topic path should not be output in logs or debug UI. Returns `true` only
    /// if there is a selection AND the topic path is included in it
    func shouldSuppress(_ topicPath: TopicPath) -> Bool
    
    /// - return: `true` if the specified feature is in the current focus selection. This must be
    /// the case if any of its ancestor Features is in the focus selection. Returns `false` if there is no selection,
    /// or there is a selection but the topic is not in it
    func isFocused(_ topicPath: TopicPath) -> Bool

    /// Called to add a feature to the focus selection
    func focus(_ topicPath: TopicPath)

    /// Called to add a feature to the focus selection
    func defocus(_ topicPath: TopicPath)
    
    /// Called to clear the focus and revert to standard behaviour
    func reset()
}

/// Syntactic sugar for call sites that have a Feature rather than a TopicPath
extension FocusSelection {
    public func shouldSuppress(feature: FeatureDefinition.Type) -> Bool {
        return shouldSuppress(TopicPath(feature.identifier.path))
    }

    public func isFocused(feature: FeatureDefinition.Type) -> Bool {
        return isFocused(TopicPath(feature.identifier.path))
    }

    public func focus(feature: FeatureDefinition.Type) {
        focus(TopicPath(feature.identifier.path))
    }

    public func defocus(feature: FeatureDefinition.Type) {
        defocus(TopicPath(feature.identifier.path))
    }
}
