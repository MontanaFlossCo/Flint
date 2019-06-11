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
/// - note: See https://bugs.swift.org/browse/SR-10831 for why this is so ugly. The type inference should
/// see the constraints fully satisfy the associated types but it doesn't, so we have to also specify the
/// associatedtype so that conforming types can compile
public protocol DismissingUIAction: UIAction where InputType == DismissUIInput, PresenterType == UIViewController {
    associatedtype InputType = DismissUIInput
    associatedtype PresenterType = UIViewController
}

public extension DismissingUIAction {
    static func perform(context: ActionContext<DismissUIInput>, presenter: UIViewController, completion: Completion) -> Completion.Status {
        presenter.dismiss(animated: context.input.animated)
        return completion.completedSync(.successWithFeatureTermination)
    }
}
#endif
