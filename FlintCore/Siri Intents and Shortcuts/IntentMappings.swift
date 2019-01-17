//
//  IntentMappings.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 10/01/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A collection of mappings from Intent type to action name + executor closures.
class IntentMappings {
    static let shared = IntentMappings()
    
    /// A mapping from Intent Type name to Intent Mapping
    private(set) var mappings: [String:IntentMapping] = [:]
    
    func addMappings(_ mappings:IntentMappings) {
        self.mappings.merge(mappings.mappings) { (a, b) -> IntentMapping in
            return b
        }
    }
    
    func forward<FeatureType, ActionType>(_ intentType: FlintIntent.Type, to binding: StaticActionBinding<FeatureType, ActionType>) where ActionType: IntentAction {
        guard #available(iOS 12, *) else {
            return
        }
        
        let executor: IntentActionExecutor = { intentInstance, presenter, completion in
            guard let intentInput = intentInstance as? ActionType.IntentType else {
                flintBug("Input passed to intent executor is not the expected intent type \(ActionType.IntentType.self), it was \(type(of: intentInstance))")
            }
            guard let intentPresenter = presenter as? ActionType.PresenterType else {
                flintBug("Presenter passed to intent executor is not the expected type \(ActionType.PresenterType.self), it was \(type(of: presenter))")
            }
            guard let input = ActionType.input(for: intentInput) else {
                return completion.completedSync(.failureWithFeatureTermination(error:DispatchIntentAction.IntentActionError.invalidInputFromIntent))
            }
            return binding.perform(input: input,
                                   presenter: intentPresenter,
                                   userInitiated: true,
                                   source: .intent,
                                   completion: completion)
        }
        let intentName = String(reflecting: intentType)
        let actionName = String(reflecting: ActionType.self)
        mappings[intentName] = IntentMapping(intentType: intentType, actionTypeName: actionName, executor: executor)
    }
    
    func mapping(for intentType: FlintIntent.Type) -> IntentMapping? {
        return mappings[String(reflecting: intentType)]
    }
}

