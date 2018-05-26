//
//  TimelineBrowserFeature.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 17/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import UIKit
import FlintCore

// Timeline browsing UI
final public class TimelineBrowserFeature: ConditionalFeature {
    public static var description: String = "UI for browsing the Timeline"
    
    public static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.iOSOnly = .any

        requirements.runtimeEnabled()
    }

    public static var isEnabled: Bool?

    public static let show = action(ShowTimelineBrowserAction.self)
    public static let hide = action(HideTimelineBrowserAction.self)

    public static func prepare(actions: FeatureActionsBuilder) {
        isEnabled = TimelineFeature.isAvailable
        actions.declare(show)
        actions.declare(hide)
    }
}

final public class ShowTimelineBrowserAction: Action {
    public typealias InputType = NoInput
    public typealias PresenterType = UIViewController
    
    public static var activityTypes: Set<ActivityEligibility> = [.perform]

    public static var description: String = "Shows a view Timeline browser UI"

    public static var hideFromTimeline: Bool = true

    public static func perform(with context: ActionContext<InputType>, using presenter: PresenterType, completion: @escaping (ActionPerformOutcome) -> Void) {
        let timelineViewController = TimelineViewController.instantiate()
        if let navigationController = presenter as? UINavigationController {
            context.logs.development?.debug("Presenting timeline VC on navigation controller")
            navigationController.pushViewController(timelineViewController, animated: true)
        } else {
            context.logs.development?.debug("Presenting timeline VC modally")
            presenter.present(timelineViewController, animated: true)
        }
        completion(.success(closeActionStack: true))
    }
}

public protocol TerminatingAction: Action {
}

extension TerminatingAction {
    public static func perform(with context: ActionContext<InputType>, using presenter: PresenterType, completion: @escaping (ActionPerformOutcome) -> Void) {
        completion(.success(closeActionStack: true))
    }
}

final public class HideTimelineBrowserAction: TerminatingAction {
    public typealias InputType = NoInput
    public typealias PresenterType = NoPresenter

    public static var activityTypes: Set<ActivityEligibility> = [.perform]

    public static var description: String = "Dismisses a Timeline browser"

    public static var hideFromTimeline: Bool = true
}

