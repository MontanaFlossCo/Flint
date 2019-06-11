//
//  DismissingUIAction.swift
//  FlintCore
//
//  Created by Marc Palmer on 24/02/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#endif

/// Actions conforming to `DismissUIAction` will automatically dismiss a presenter that is a `UIViewController`
/// on UIKit platforms.
///
/// Example usage:
/// ```
/// final class ShowProfileFeature: Feature {
///     let dismiss = action(DismissShowProfileAction.self)
///     ...
/// }
///
/// final class DismissShowProfileAction: DismissingUIAction {
/// }
///
/// // Then, in some app code:
///
/// ShowProfileFeature.dismiss.perform(withInput: .animated(true))
/// ```
/// - see: `DismissUIInput`
/// 

/// Public typealias for consistency with FlintUIAction which is a convenience to avoid full namespacing
/// of FlintCore.xxxAction on iOS 13
public typealias FlintDimissUIAction = DismissingUIAction

#if os(iOS) || os(tvOS)
public protocol DismissingUIAction: UIAction {
    associatedtype InputType = DismissUIInput
    associatedtype PresenterType = UIViewController
}

public extension DismissingUIAction where InputType == DismissUIInput, PresenterType == UIViewController {
    static func perform(context: ActionContext<DismissUIInput>, presenter: UIViewController, completion: Completion) -> Completion.Status {
        presenter.dismiss(animated: context.input.animated)
        return completion.completedSync(.successWithFeatureTermination)
    }
}
#endif
