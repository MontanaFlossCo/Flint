//
//  FeatureActionsBuilder.swift
//  FlintCore
//
//  Created by Marc Palmer on 18/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The actions builder protocol defines the domain-specific-language used to declare
/// the actions available on a feature.
public protocol FeatureActionsBuilder {

    /// Declare an action that is always available. This will bind the action and the feature, so that the
    /// action can be performed.
    func declare<FeatureType, ActionType>(_ action: StaticActionBinding<FeatureType, ActionType>)
    func declare<FeatureType, ActionType>(_ action: StaticActionBinding<FeatureType, ActionType>) where ActionType.InputType: ActivityCodable

    /// Declare an action that is conditionally available. This will bind the action and the feature, so that the
    /// action can be performed.
    func declare<FeatureType, ActionType>(_ action: ConditionalActionBinding<FeatureType, ActionType>)
    func declare<FeatureType, ActionType>(_ action: ConditionalActionBinding<FeatureType, ActionType>) where ActionType.InputType: ActivityCodable

    /// Publish an action that is always available. This will bind the action and the feature, so that the
    /// action can be performed. Published actions can be enumerated separately by the application to
    /// provide UI for them.
    func publish<FeatureType, ActionType>(_ action: StaticActionBinding<FeatureType, ActionType>)
    func publish<FeatureType, ActionType>(_ action: StaticActionBinding<FeatureType, ActionType>) where ActionType.InputType: ActivityCodable

    /// Publishes an action that is conditionally available. This will bind the action and the feature, so that the
    /// action can be performed. Published actions can be enumerated separately by the application to
    /// provide UI for them.
    func publish<FeatureType, ActionType>(_ action: ConditionalActionBinding<FeatureType, ActionType>)
    func publish<FeatureType, ActionType>(_ action: ConditionalActionBinding<FeatureType, ActionType>) where ActionType.InputType: ActivityCodable
}
