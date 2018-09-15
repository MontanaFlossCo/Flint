//
//  LogBrowserFeature.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 17/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import UIKit
import FlintCore

/// Probides a UI for browsing the Focus logs
final public class LogBrowserFeature: ConditionalFeature {
    public static var description: String = "UI for browsing the Focus logs"

    public static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.iOSOnly = .any

        requirements.runtimeEnabled()
    }

    public static var isEnabled: Bool?

    public static let show = action(ShowLogBrowserAction.self)
    
    public static func prepare(actions: FeatureActionsBuilder) {
         isEnabled = FocusFeature.isEnabled
         actions.declare(show)
    }
}

final public class ShowLogBrowserAction: UIAction {
    public typealias InputType = NoInput
    public typealias PresenterType = UIViewController
    
    public static var description: String = "Shows a UI for browsing the Focus logs"

    public static var hideFromTimeline: Bool = true

    public static func perform(context: ActionContext<InputType>, presenter: PresenterType, completion: Completion) -> Completion.Status {
        let focusLogViewController = FocusLogViewController.instantiate()
        if let navigationController = presenter as? UINavigationController {
            context.logs.development?.debug("Presenting Focus Log VC on navigation controller")
            navigationController.pushViewController(focusLogViewController, animated: true)
        } else {
            context.logs.development?.debug("Presenting Focus Log VC modally")
            presenter.present(focusLogViewController, animated: true)
        }
        return completion.completedSync(.successWithFeatureTermination)
    }
}

