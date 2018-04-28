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
    
    public static var availability: FeatureAvailability = .custom
    public static var isAvailable: Bool? { return FocusFeature.isAvailable }

    public static let show = action(ShowLogBrowserAction.self)
    
    public static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(show)
    }
}

final public class ShowLogBrowserAction: Action {
    public typealias InputType = NoInput
    public typealias PresenterType = UIViewController
    
    public static var description: String = "Shows a UI for browsing the Focus logs"

    public static var hideFromTimeline: Bool = true

    public static func perform(with context: ActionContext<InputType>, using presenter: PresenterType, completion: @escaping (ActionPerformOutcome) -> Void) {
        let focusLogViewController = FocusLogViewController.instantiate()
        if let navigationController = presenter as? UINavigationController {
            context.logs.development?.debug("Presenting Focus Log VC on navigation controller")
            navigationController.pushViewController(focusLogViewController, animated: true)
        } else {
            context.logs.development?.debug("Presenting Focus Log VC modally")
            presenter.present(focusLogViewController, animated: true)
        }
        completion(.success(closeActionStack: true))
    }
}

