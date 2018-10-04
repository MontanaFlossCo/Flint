//
//  IntentMapped.swift
//  FlintCore
//
//  Created by Marc Palmer on 04/10/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(Intents)
import Intents
#endif

public protocol IntentMappingsBuilder {
    // Declare that incoming continued intents of this type must be forward to this action
    func forward<FeatureType, ActionType>(intentType: INIntent.Type, to actionBinding: StaticActionBinding<FeatureType, ActionType>) where FeatureType: FeatureDefinition, ActionType: Action 
}

public class DefaultIntentMappingsBuilder: IntentMappingsBuilder {
    var mappings: [ObjectIdentifier:Any] = [:]
    
    public func forward<FeatureType, ActionType>(intentType: INIntent.Type, to actionBinding: StaticActionBinding<FeatureType, ActionType>) where FeatureType: FeatureDefinition, ActionType: Action {
        mappings[ObjectIdentifier(intentType)] = actionBinding
    }
}

public protocol IntentMapped where Self: Feature {
    static func intentMappings(intents: IntentMappingsBuilder)
}

