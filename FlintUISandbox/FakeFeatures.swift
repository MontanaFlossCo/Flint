//
//  FakeFeatures.swift
//  FlintUISandbox
//
//  Created by Marc Palmer on 11/07/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import FlintCore

class FakeFeatures: FeatureGroup {
    static var name = "MyFakeFeaturesAliased"
    static var subfeatures: [FeatureDefinition.Type] = [FakeFeature.self]
}

final class FakeFeature: ConditionalFeature {
    static var name = "FakeFeature1"
    
    static var description = "A fake feature"
    
    static let action1: ConditionalActionBinding<FakeFeature, DoSomethingFakeAction> = action(DoSomethingFakeAction.self)
    
    static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(action1)
    }

    static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.iOSOnly = 10
        requirements.permission(.camera)
        requirements.permission(.photos)
        requirements.permission(.contacts(entity: .contacts))
    }
}

final class DoSomethingFakeAction: Action {
    typealias InputType = NoInput
    typealias PresenterType = NoPresenter
    
    static var activityTypes: Set<ActivityEligibility> = [.handoff, .prediction]

    static func prepareActivity(_ activity: ActivityBuilder<InputType>) {
        activity.title = "Do a fake thing"
        activity.subtitle = "This will show up in Siri shortcuts on iOS 12"
        activity.requiredUserInfoKeys = ["fake"]
        activity.userInfo["fake"] = true
    }

    static func perform(with context: ActionContext<InputType>, using presenter: PresenterType, completion: @escaping (ActionPerformOutcome) -> Void) {
        context.logs.development?.info("Testing logs from fake feature")
        completion(.success(closeActionStack: true))
    }
}
