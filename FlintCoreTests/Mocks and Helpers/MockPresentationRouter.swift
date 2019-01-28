//
//  MockPresentationRouter.swift
//  FlintCore-iOS
//
//  Created by Alvin Choo on 28/1/19.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
class MockPresentationRouter: PresentationRouter {
    
    var dummyViewController = MockViewController()
    
    func presentation<FeatureType, ActionType>(for conditionalActionBinding: ConditionalActionBinding<FeatureType, ActionType>, input: ActionType.InputType) -> PresentationResult<ActionType.PresenterType> where FeatureType : ConditionalFeature, ActionType : Action {
        
        if ActionType.PresenterType.self == MockViewController.self {
            return .appReady(presenter: dummyViewController as! ActionType.PresenterType)
        }
        
        return .unsupported
    }
    
    
    func presentation<FeatureType, ActionType>(for actionBinding: StaticActionBinding<FeatureType, ActionType>, input: ActionType.InputType) -> PresentationResult<ActionType.PresenterType> where FeatureType : FeatureDefinition, ActionType : Action {
        if ActionType.PresenterType.self == MockViewController.self {
            return .appReady(presenter: dummyViewController as! ActionType.PresenterType)
        }
        
        return .unsupported
    }
}

class MockViewController: UIViewController {
    
}
