//
//  TopicPath+Extensions.swift
//  FlintCore
//
//  Created by Marc Palmer on 03/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Feature-specific extensions as a convenience for creating TopicPath instances
public extension TopicPath {
    init(feature: FeatureDefinition.Type) {
        self.init([String(describing: feature)])
    }

    init<FeatureType, ActionType>(actionBinding: StaticActionBinding<FeatureType, ActionType>) {
        self.init(FeatureType.identifier.path + ["#\(String(describing: ActionType.self))"])
    }

    init<FeatureType, ActionType>(actionBinding: ConditionalActionBinding<FeatureType, ActionType>) {
        self.init(FeatureType.identifier.path + ["#\(String(describing: ActionType.self))"])
    }
}
