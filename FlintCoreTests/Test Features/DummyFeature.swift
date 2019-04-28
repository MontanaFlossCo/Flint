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

final class DummyFeature: Feature {
    static var description: String = "Test feature"

    static let action1 = action(DummyAction.self)

#if canImport(Network) && os(iOS)
    @available(iOS 12, *)
    static let intentAction = action(DummyIntentAction.self)
#endif

    static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(action1)
#if canImport(Network) && os(iOS)
        if #available(iOS 12, *) {
            actions.declare(intentAction)
        }
#endif
    }
}

final class DummyAction: UIAction {
    typealias InputType = NoInput
    typealias PresenterType = NoPresenter
    
    static func perform(context: ActionContext<DummyAction.InputType>, presenter: DummyAction.PresenterType, completion: Action.Completion) -> Action.Completion.Status {
        return completion.completedSync(.successWithFeatureTermination)
    }
}

typealias DummyIntent = FlintIntent
typealias DummyIntentResponse = FlintIntentResponse

#if canImport(Network) && os(iOS)
@available(iOS 12, *)
final class DummyIntentAction: IntentAction {
    typealias IntentType = DummyIntent
    typealias PresenterType = IntentResponsePresenter<DummyIntentResponse>
    typealias IntentResponseType = DummyIntentResponse
    
    static func intent(input: DummyIntentAction.InputType) -> DummyIntent? {
        return DummyIntent()
    }
    
    static func input(from intent: DummyIntent) -> DummyIntentAction.InputType? {
        return .noInput
    }
    
    static func perform(context: ActionContext<NoInput>, presenter: PresenterType, completion: Action.Completion) -> Action.Completion.Status {
        return completion.completedSync(.successWithFeatureTermination)
    }
}
#endif
