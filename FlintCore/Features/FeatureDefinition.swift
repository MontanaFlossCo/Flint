//
//  Feature.swift
//  FlintCore
//
//  Created by Marc Palmer on 09/10/2017.
//  Copyright © 2017 Montana Floss Co. All rights reserved.
//

import Foundation

/// This is the basic information for all features of an application or framework.
/// Use specific sub-protocols `Feature` and `ConditionalFeature` in your code.
///
/// - see: `Feature` and `ConditionalFeature`
/// - note: Accesses to any properties that may change at runtime, e.g. `variation` must only occur on the main thread.
public protocol FeatureDefinition: AnyObject {
    /// Returns a user-friendly name for this feature
    static var name: String { get }

    /// Returns a user-friendly description for this feature
    static var description: String { get }
    
    /// Return `true` if this feature should appear in Feature selection UIs, such as toolbars.
    /// - note: This is purely for app use to categories some features as being surfaced in the UI. Visibility of
    /// individual actions is controlled by whether or not they are `publish()`'d in the `prepare` function of the feature.
    /// - note: Accesses to any properties that may change at runtime must only occur on the main thread.
    static var isVisible: Bool { get }

    /// Return the ID of a variation if this feature, if applicable for e.g. A/B testing.
    /// `Action.perform` can look at this value to decide how to implement the action based on this value.
    /// - note: Accesses to any properties that may change at runtime must only occur on the main thread.
    static var variation: String? { get }

    /// Called to initialise the feature at startup.
    /// Actionable implementations must call `declare` for all actions they support inside
    /// this function.
    /// - note: May be called multiple times in tests
    static func prepare(actions: FeatureActionsBuilder)

    /// Called to allow the feature to do any post-preparation after all features in the same feature group
    /// have prepared their actions.
    ///
    /// Default implementation does nothing, override only if you need to do something.
    static func postPrepare()
}

/// Default implementations of the properties
public extension FeatureDefinition {
    /// This property is a convenience for the internal `Flint.parent(of: self)`.
    /// Don't shadow it on your own Feature types by accident! If you override this
    /// you must declare its type explicitly as the optional `FeatureGroup.Type?` to
    /// prevent this problem.
    ///
    /// - return: the parent feature group of this feature, if any. Flint automatically handles this during preparation
    /// and stashes the parent info in the `Flint` object.
    static var parent: FeatureGroup.Type? { return Flint.parent(of: self) }
    
    /// Generate the identifier using the feature-parent relationship to achieve nested IDs.
    /// This is not part of the public API, as IDs are for internal use only.
    /// !!! TODO: Memoize this so it is not recreating every time.
    static var identifier: FeaturePath {
        if let parent = Flint.parent(of: self) {
            return parent.identifier.appending(feature: self)
        } else {
            return FeaturePath(feature: self)
        }
    }
    
    /// Generate the default name using the type name converted from camel case
    /// !!! TODO: Memoize this so it is not recreating every time.
    static var name: String {
        let typeName = String(describing: self)
        var parts = typeName.camelCaseToTokens()
        if parts.last == "Feature" {
            parts.remove(at: parts.count-1)
        }
        return parts.joined(separator: " ")
    }
    
    /// By default, features are not visible to the user
    static var isVisible: Bool { return false }

    /// By default, no variation. Override and supply your own variation values using whatever system you
    /// have for determining the A/B testing variations.
    static var variation: String? { return nil }

    /// NO-OP
    static func postPrepare() {
    }
}

public extension FeatureDefinition {

    /// Returns a set of new context-specific loggers with this feature as the context (topic path).
    ///
    /// - param activity: A string that identifies the kind of activity that will be generating log entries, e.g. "bg upload"
    /// - return: A `Logs` value which contains development and production loggers as appropriate at runtime.
    static func logs(for activity: String) -> ContextualLoggers {
        let development: ContextSpecificLogger?
        if let factory = Logging.development {
            development = factory.contextualLogger(with: activity, topicPath: self.identifier)
        } else {
            development = nil
        }

        let production: ContextSpecificLogger?
        if let factory = Logging.development {
            production = factory.contextualLogger(with: activity, topicPath: self.identifier)
        } else {
            production = nil
        }

        return ContextualLoggers(development: development, production: production)
    }
    
    /// Convenience function to set the level of logging for this feature and subfeatures
    static func setLoggingLevel(_ level: LoggerLevel) {
        Logging.development?.setLevel(for: self.identifier, to: level)
        Logging.production?.setLevel(for: self.identifier, to: level)
    }

    /// Convenience function to turn off logging for this feature and subfeatures
    static func disableLogging() {
        setLoggingLevel(.none)
    }
}
