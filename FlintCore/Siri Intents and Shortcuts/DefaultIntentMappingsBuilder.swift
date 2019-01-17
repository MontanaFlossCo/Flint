//
//  DefaultIntentMappingsBuilder.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 10/01/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The implementation of the Intent mappings builder that stores the mappings for copying into metadata.
///
/// - see: `Flint.performIntent`
public class DefaultIntentMappingsBuilder<FeatureType>: IntentMappingsBuilder where FeatureType: FeatureDefinition {
    var mappings = IntentMappings()
    
    public func forward<FeatureType, ActionType>(intentType: FlintIntent.Type, to actionBinding: StaticActionBinding<FeatureType, ActionType>) where ActionType: IntentAction {
        mappings.forward(intentType, to: actionBinding)
    }
}
