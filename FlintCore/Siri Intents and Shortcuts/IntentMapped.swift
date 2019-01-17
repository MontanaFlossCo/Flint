//
//  IntentMapped.swift
//  FlintCore
//
//  Created by Marc Palmer on 04/10/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A protocol that must be adopted by features that map Siri Intent types to Actions, so they can be performed
/// at runtime via a Siri Intent Extension
public protocol IntentMapped: FeatureDefinition {
    /// Features must implement this function and call builder funtions to define their mappings.
    static func intentMappings(intents: IntentMappingsBuilder)
}

extension IntentMapped where Self: FeatureDefinition {
    static func collectIntentMappings() -> IntentMappings {
        let builder: DefaultIntentMappingsBuilder<Self> = DefaultIntentMappingsBuilder<Self>()
        intentMappings(intents: builder)
        return builder.mappings
    }
}

