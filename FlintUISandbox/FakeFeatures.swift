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

final class FakeFeature: ConditionalFeature, URLMapped {
    static var name = "FakeFeature1"
    
    static var description = "A fake feature"
    
    static let action1 = action(DoSomethingFakeAction.self)
    
    static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(action1)
    }

    static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.iOSOnly = 10
        requirements.permission(.camera)
        requirements.permission(.photos)
        requirements.permission(.contacts(entity: .contacts))
    }
    
    static func urlMappings(routes: URLMappingsBuilder) {
        routes.send("/test", to: action1)
    }
}

extension String: RouteParametersCodable {
    public init?(from routeParameters: RouteParameters?, mapping: URLMapping) {
        guard let value = routeParameters?["value"] else {
            return nil
        }
        self.init(value)
    }
    
    public func encodeAsRouteParameters(for mapping: URLMapping) -> RouteParameters? {
        return ["value": self]
    }
    
}

final class DoSomethingFakeAction: UIAction {
    typealias InputType = String?
    typealias PresenterType = NoPresenter
    
    static var activityEligibility: Set<ActivityEligibility> = [.handoff, .prediction]

    static func prepareActivity(_ activity: ActivityBuilder<DoSomethingFakeAction>) {
        activity.title = "Do a fake thing"
        activity.subtitle = "This will show up in Siri shortcuts on iOS 12"
        activity.requiredUserInfoKeys = ["fake"]
        activity.userInfo["fake"] = true
    }

    static func perform(context: ActionContext<InputType>, presenter: PresenterType, completion: Completion) -> Completion.Status {
        context.logs.development?.info("Testing logs from fake feature")
        return completion.completedSync(.successWithFeatureTermination)
    }
}
