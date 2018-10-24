//
//  DummyFeature.swift
//  FlintCore
//
//  Created by Marc Palmer on 17/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import FlintCore

class DummyFeatures: FeatureGroup {
    static var subfeatures: [FeatureDefinition.Type] = [DummyStaticFeature.self]
}

final class DummyStaticFeature: Feature {
    static var description: String = "Test feature"
    static let action1 = action(DummyAction.self)
    
    static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(action1)
    }
}

final class DummyAction: UIAction {
    typealias InputType = NoInput
    typealias PresenterType = NoPresenter
    
    static func perform(context: ActionContext<DummyAction.InputType>, presenter: DummyAction.PresenterType, completion: Action.Completion) -> Action.Completion.Status {
        return completion.completedSync(.successWithFeatureTermination)
    }
}
