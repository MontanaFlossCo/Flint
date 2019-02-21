//
//  PurchaseBrowserFeature.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 20/02/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import FlintCore

final public class PurchaseBrowserFeature: ConditionalFeature {
    public static var description: String = "UI for browsing the status of Purchases"
    
    public static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.iOSOnly = .any

        requirements.runtimeEnabled()
    }

    public static var isEnabled: Bool?

    public static let show = action(ShowPurchaseBrowserAction.self)
    public static let hide = action(HidePurchaseBrowserAction.self)

    public static func prepare(actions: FeatureActionsBuilder) {
        isEnabled = Flint.purchaseTracker != nil
        actions.declare(show)
        actions.declare(hide)
    }
}

final public class ShowPurchaseBrowserAction: UIAction {
    public typealias InputType = NoInput
    public typealias PresenterType = UIViewController
    
    public static var description: String = "Shows a UI for browsing the status of Purchases"

    public static var hideFromTimeline: Bool = true

    public static func perform(context: ActionContext<InputType>, presenter: PresenterType, completion: Completion) -> Completion.Status {
        let purchaseStatusViewController = PurchaseBrowserViewController.instantiate()
        if let navigationController = presenter as? UINavigationController {
            context.logs.development?.debug("Presenting Purchase Status VC on navigation controller")
            navigationController.pushViewController(purchaseStatusViewController, animated: true)
        } else {
            context.logs.development?.debug("Presenting Purchase Status VC modally")
            presenter.present(purchaseStatusViewController, animated: true)
        }
        return completion.completedSync(.successWithFeatureTermination)
    }
}

final public class HidePurchaseBrowserAction: DismissingUIAction {
    public static var description: String = "Dismisses a Purchase browser"

    public static var hideFromTimeline: Bool = true
}

