//
//  IntentMappingsBuilder.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 10/01/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation


public protocol IntentMappingsBuilder {
    // Declare that incoming continued intents of this type must be forward to this action
    func forward<FeatureType, ActionType>(intentType: FlintIntent.Type, to actionBinding: StaticActionBinding<FeatureType, ActionType>) where ActionType: Action, ActionType.InputType: FlintIntent, ActionType.PresenterType: IntentResultPresenter
}
