//
//  DummyFeature.swift
//  FlintCore
//
//  Created by Marc Palmer on 17/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import FlintCore
#if canImport(Intents)
import Intents
#endif

class DummyFeatures: FeatureGroup {
    static var subfeatures: [FeatureDefinition.Type] = [
        DummyFeature.self
    ]
}

final class DummyFeature: Feature, IntentMapped {
    static var description: String = "Test feature"
    static let action1 = action(DummyAction.self)
    static let intentAction = action(DummyIntentAction.self)

    static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(action1)
        actions.declare(intentAction)
    }

    static func intentMappings(intents: IntentMappingsBuilder) {
        intents.forward(intentType: DummyIntent.self, to: intentAction)
    }
}

final class DummyAction: UIAction {
    typealias InputType = NoInput
    typealias PresenterType = NoPresenter
    
    static func perform(context: ActionContext<DummyAction.InputType>, presenter: DummyAction.PresenterType, completion: Action.Completion) -> Action.Completion.Status {
        return completion.completedSync(.successWithFeatureTermination)
    }
}

class DummyIntent: FlintIntent {
}

class DummyIntentResultPresenter: IntentResultPresenter {
    func showResult(response: FlintIntentResponse) {
    }
}

final class DummyIntentAction: IntentAction {
    typealias InputType = DummyIntent
    typealias PresenterType = DummyIntentResultPresenter
    
    static func perform(context: ActionContext<DummyIntentAction.InputType>, presenter: DummyIntentAction.PresenterType, completion: Action.Completion) -> Action.Completion.Status {
        return completion.completedSync(.successWithFeatureTermination)
    }
}
