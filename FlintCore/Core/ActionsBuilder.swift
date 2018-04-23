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
    
    init(feature: FeatureDefinition.Type) {
        self.feature = feature
    }
    
    public func declare<FeatureType, ActionType>(_ binding: StaticActionBinding<FeatureType, ActionType>) {
        Flint.bind(binding.action, to: feature)
    }
    
    public func declare<FeatureType, ActionType>(_ binding: ConditionalActionBinding<FeatureType, ActionType>) {
        Flint.bind(binding.action, to: feature)
    }

    public func publish<FeatureType, ActionType>(_ binding: StaticActionBinding<FeatureType, ActionType>) {
        Flint.publish(binding.action, to: feature)
    }
    
    public func publish<FeatureType, ActionType>(_ binding: ConditionalActionBinding<FeatureType, ActionType>) {
        Flint.publish(binding.action, to: feature)
    }
}
