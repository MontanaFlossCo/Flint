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

#if canImport(Intents)
public typealias FlintIntent = INIntent
#else
public class FalseIntent {
}
public typealias FlintIntent = FalseIntent
#endif

extension FlintIntent: FlintLoggable {

}

public protocol IntentMappingsBuilder {
    // Declare that incoming continued intents of this type must be forward to this action
    func forward<FeatureType, ActionType>(intentType: FlintIntent.Type, to actionBinding: StaticActionBinding<FeatureType, ActionType>) where ActionType: Action, ActionType.InputType: FlintIntent, ActionType.PresenterType: IntentResultPresenter
}

public class DefaultIntentMappingsBuilder<FeatureType>: IntentMappingsBuilder where FeatureType: FeatureDefinition {
    var mappings = IntentMappings()
    
    public func forward<FeatureType, ActionType>(intentType: FlintIntent.Type, to actionBinding: StaticActionBinding<FeatureType, ActionType>) where ActionType: Action, ActionType.InputType: FlintIntent, ActionType.PresenterType: IntentResultPresenter {
        mappings.forward(intentType, to: actionBinding)
    }
}

public protocol IntentMapped: FeatureDefinition {
    static func intentMappings(intents: IntentMappingsBuilder)
}

public typealias LoggableIntent = FlintIntent & FlintLoggable

public typealias IntentActionExecutor = (_ input: FlintIntent, _ presenter: IntentResultPresenter, _ completion: Action.Completion) -> Action.Completion.Status

struct IntentMapping {
    let intentType: FlintIntent.Type
    let actionTypeName: String
    let executorProxy: (_ intent: FlintIntent, _ presenter: IntentResultPresenter, _ completion: Action.Completion) -> Action.Completion.Status
    
    init(intentType: FlintIntent.Type, actionTypeName: String, executor: @escaping IntentActionExecutor) {
        self.intentType = intentType
        self.actionTypeName = actionTypeName
        executorProxy = { (input: FlintIntent, presenter: IntentResultPresenter, completion: Action.Completion) -> Action.Completion.Status in
            executor(input, presenter, completion)
        }
    }

    func performAction(for intent: FlintIntent, presenter: IntentResultPresenter, completion: Action.Completion) -> Action.Completion.Status {
        return executorProxy(intent, presenter, completion)
    }
}

class IntentMappings {
    static let shared = IntentMappings()
    
    /// A mapping from Intent Type name to Intent Mapping
    private(set) var mappings: [String:IntentMapping] = [:]
    
    func addMappings(_ mappings:IntentMappings) {
        self.mappings.merge(mappings.mappings) { (a, b) -> IntentMapping in
            return b
        }
    }
    
    func forward<FeatureType, ActionType>(_ intentType: FlintIntent.Type, to binding: StaticActionBinding<FeatureType, ActionType>) where ActionType.InputType: LoggableIntent, ActionType.PresenterType: IntentResultPresenter {
        let executor: IntentActionExecutor = { input, presenter, completion in
            guard let intentInput = input as? ActionType.InputType else {
                flintBug("Input passed to intent executor is not the expected type \(ActionType.InputType.self), it was \(type(of: input))")
            }
            guard let intentPresenter = presenter as? ActionType.PresenterType else {
                flintBug("Presentr passed to intent executor is not the expected type \(ActionType.PresenterType.self), it was \(type(of: presenter))")
            }
            return binding.perform(input: intentInput,
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

extension IntentMapped where Self: FeatureDefinition {
    static func collectIntentMappings() -> IntentMappings {
        let builder: DefaultIntentMappingsBuilder<Self> = DefaultIntentMappingsBuilder<Self>()
        intentMappings(intents: builder)
        return builder.mappings
    }
}

