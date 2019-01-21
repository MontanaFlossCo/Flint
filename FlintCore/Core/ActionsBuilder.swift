//
//  ActionsBuilder.swift
//  FlintCore
//
//  Created by Marc Palmer on 22/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The builder used to take action bindings register them with Flint internals so that the
/// static action definitions get evaluated and they can be prepared fully.
class ActionsBuilder: FeatureActionsBuilder {
    let feature: FeatureDefinition.Type
    let activityMappings: ActionActivityMappings
    
    init(feature: FeatureDefinition.Type, activityMappings: ActionActivityMappings) {
        self.feature = feature
        self.activityMappings = activityMappings
    }
    
    public func declare<FeatureType, ActionType>(_ binding: StaticActionBinding<FeatureType, ActionType>) {
        Flint.bind(ActionType.self, to: FeatureType.self)
    }
    
    public func declare<FeatureType, ActionType>(_ binding: StaticActionBinding<FeatureType, ActionType>) where ActionType.InputType: ActivityCodable {
        activityMappings.registerActivity(for: binding)
        Flint.bind(ActionType.self, to: FeatureType.self)
    }
    
    public func declare<FeatureType, ActionType>(_ binding: ConditionalActionBinding<FeatureType, ActionType>) {
        Flint.bind(ActionType.self, to: FeatureType.self)
    }

    public func declare<FeatureType, ActionType>(_ binding: ConditionalActionBinding<FeatureType, ActionType>) where ActionType.InputType: ActivityCodable {
        activityMappings.registerActivity(for: binding)
        Flint.bind(ActionType.self, to: FeatureType.self)
    }

    public func publish<FeatureType, ActionType>(_ binding: StaticActionBinding<FeatureType, ActionType>) {
        Flint.publish(ActionType.self, to: FeatureType.self)
    }

    public func publish<FeatureType, ActionType>(_ binding: StaticActionBinding<FeatureType, ActionType>) where ActionType.InputType: ActivityCodable {
        activityMappings.registerActivity(for: binding)
        Flint.publish(ActionType.self, to: FeatureType.self)
    }
    
    public func publish<FeatureType, ActionType>(_ binding: ConditionalActionBinding<FeatureType, ActionType>) {
        Flint.publish(ActionType.self, to: FeatureType.self)
    }

    
    public func publish<FeatureType, ActionType>(_ binding: ConditionalActionBinding<FeatureType, ActionType>) where ActionType.InputType: ActivityCodable {
        activityMappings.registerActivity(for: binding)
        Flint.publish(ActionType.self, to: FeatureType.self)
    }

#if canImport(Network) && os(iOS)
    @available(iOS 12, *)
    public func declare<FeatureType, ActionType>(_ binding: StaticActionBinding<FeatureType, ActionType>) where ActionType: IntentAction, ActionType.InputType: ActivityCodable {
        activityMappings.registerActivity(for: binding)
        Flint.bind(ActionType.self, to: FeatureType.self)
    }
    
    @available(iOS 12, *)
    public func declare<FeatureType, ActionType>(_ binding: ConditionalActionBinding<FeatureType, ActionType>) where ActionType: IntentAction {
        Flint.bind(ActionType.self, to: FeatureType.self)
    }

    @available(iOS 12, *)
    public func declare<FeatureType, ActionType>(_ binding: ConditionalActionBinding<FeatureType, ActionType>) where ActionType: IntentAction, ActionType.InputType: ActivityCodable {
        activityMappings.registerActivity(for: binding)
        Flint.bind(ActionType.self, to: FeatureType.self)
    }

    @available(iOS 12, *)
    public func publish<FeatureType, ActionType>(_ binding: StaticActionBinding<FeatureType, ActionType>) where ActionType: IntentAction {
        Flint.publish(ActionType.self, to: FeatureType.self)
    }
    
    @available(iOS 12, *)
    public func declare<FeatureType, ActionType>(_ binding: StaticActionBinding<FeatureType, ActionType>) where ActionType: IntentAction {
        Flint.bind(ActionType.self, to: FeatureType.self)
    }
    
    @available(iOS 12, *)
    public func publish<FeatureType, ActionType>(_ binding: StaticActionBinding<FeatureType, ActionType>) where ActionType: IntentAction, ActionType.InputType: ActivityCodable {
        activityMappings.registerActivity(for: binding)
        Flint.publish(ActionType.self, to: FeatureType.self)
    }
    
    @available(iOS 12, *)
    public func publish<FeatureType, ActionType>(_ binding: ConditionalActionBinding<FeatureType, ActionType>) where ActionType: IntentAction {
        Flint.publish(ActionType.self, to: FeatureType.self)
    }

    @available(iOS 12, *)
    public func publish<FeatureType, ActionType>(_ binding: ConditionalActionBinding<FeatureType, ActionType>) where ActionType: IntentAction, ActionType.InputType: ActivityCodable {
        activityMappings.registerActivity(for: binding)
        Flint.publish(ActionType.self, to: FeatureType.self)
    }
#endif
}
