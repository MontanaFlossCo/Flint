//
//  FeatureBrowserFeature.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 17/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import UIKit
import FlintCore

/// Provides a UI for browsing the features and actions registered in the application
final public class FeatureBrowserFeature: ConditionalFeature {
    public static var description: String = "UI for browsing the Features and Actions of the app"
    
    public static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.iOSOnly = .any
    }

    public static let show = action(ShowFeatureBrowserAction.self)
    
    public static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(show)
    }
}


final public class ShowFeatureBrowserAction: Action {
    public typealias InputType = NoInput
    public typealias PresenterType = UIViewController
    
    public static var description: String = "Shows a UI for browsing the Features and Actions"

    public static var hideFromTimeline: Bool = true

    public static func perform(context: ActionContext<InputType>, presenter: PresenterType, completion: Completion) -> Completion.Status {
        let featuresViewController = FeatureBrowserViewController.instantiate()
        if let navigationController = presenter as? UINavigationController {
            navigationController.pushViewController(featuresViewController, animated: true)
        } else {
            presenter.present(featuresViewController, animated: true)
        }
        return completion.completedSync(.success(closeActionStack: true))
    }
}
