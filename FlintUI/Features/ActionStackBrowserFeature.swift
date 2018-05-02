//
//  ActionStackBrowserFeature.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 17/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import UIKit
import FlintCore

/// Display of the current Action Stacks
final public class ActionStackBrowserFeature: ConditionalFeature {
    public static var description: String = "UI for browsing the active Action Stacks"
    
    public static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.precondition(.iOS(.any))
    }

    public static let show = action(ShowActionStackBrowserAction.self)
    
    public static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(show)
    }
}

final public class ShowActionStackBrowserAction: Action {
    public typealias InputType = NoInput
    public typealias PresenterType = UIViewController
    
    public static var description: String = "Shows the UI for browsing the active Action Stacks"

    public static var hideFromTimeline: Bool = true

    public static func perform(with context: ActionContext<InputType>, using presenter: PresenterType, completion: @escaping (ActionPerformOutcome) -> Void) {
        let actionStacksViewController = ActionStackListViewController.instantiate()
        if let navigationController = presenter as? UINavigationController {
            navigationController.pushViewController(actionStacksViewController, animated: true)
        } else {
            presenter.present(actionStacksViewController, animated: true)
        }
        completion(.success(closeActionStack: true))
    }
}


