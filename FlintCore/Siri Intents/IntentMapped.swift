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

extension INIntent: FlintLoggable {

}

public protocol IntentMappingsBuilder {
    associatedtype FeatureType: FeatureDefinition
    
    // Declare that incoming continued intents of this type must be forward to this action
    func forward<ActionType>(intentType: INIntent.Type, to actionBinding: StaticActionBinding<FeatureType, ActionType>) where ActionType: Action, ActionType.InputType: INIntent, ActionType.PresenterType: IntentResultPresenter
}

public class DefaultIntentMappingsBuilder<FeatureType>: IntentMappingsBuilder where FeatureType: FeatureDefinition {
    var mappings = IntentMappings()
    
    public func forward<ActionType>(intentType: INIntent.Type, to actionBinding: StaticActionBinding<FeatureType, ActionType>) where ActionType: Action, ActionType.InputType: INIntent, ActionType.PresenterType: IntentResultPresenter {
        mappings.forward(intentType, to: actionBinding)
    }
}

public protocol IntentMapped where Self: FeatureDefinition {
    static func intentMappings<BuilderType>(intents: BuilderType) where BuilderType: IntentMappingsBuilder, BuilderType.FeatureType == Self
}

public typealias LoggableIntent = INIntent & FlintLoggable

public typealias IntentActionExecutor = (_ input: INIntent, _ presenter: IntentResultPresenter, _ completion: Action.Completion) -> Action.Completion.Status

struct IntentActionMapping {
    let executorProxy: (_ intent: INIntent, _ presenter: IntentResultPresenter, _ completion: Action.Completion) -> Action.Completion.Status
    
    init(executor: @escaping IntentActionExecutor) {
        executorProxy = { (input: INIntent, presenter: IntentResultPresenter, completion: Action.Completion) -> Action.Completion.Status in
            executor(input, presenter, completion)
        }
    }

    func performAction(for intent: INIntent, presenter: IntentResultPresenter, completion: Action.Completion) -> Action.Completion.Status {
        return executorProxy(intent, presenter, completion)
    }
}

class IntentMappings {
    static let instance = IntentMappings()
    
    var mappings: [ObjectIdentifier:IntentActionMapping] = [:]
    
    func forward<FeatureType, ActionType>(_ intentType: INIntent.Type, to binding: StaticActionBinding<FeatureType, ActionType>) where ActionType.InputType: LoggableIntent, ActionType.PresenterType: IntentResultPresenter {
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
        mappings[ObjectIdentifier(intentType)] = IntentActionMapping(executor: executor)
    }
    
    func mapping(for intentType: INIntent.Type) -> IntentActionMapping? {
        return mappings[ObjectIdentifier(intentType)]
    }
}

extension IntentMapped where Self: FeatureDefinition {
    static func collectIntentMappings() -> IntentMappings {
        let builder: DefaultIntentMappingsBuilder<Self> = DefaultIntentMappingsBuilder<Self>()
        intentMappings(intents: builder)
        return builder.mappings
    }
}

