//
//  DismissingUIAction.swift
//  FlintCore
//
//  Created by Marc Palmer on 24/02/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import UIKit

#if os(iOS) || os(tvOS)
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
/// final class DismissShowProfileAction: DismissUIAction {
/// }
///
/// // Then, in some app code:
///
/// ShowProfileFeature.dismiss.perform(input: .animated(true))
///
/// ```
/// - see: `DismissUIInput`
public protocol DismissingUIAction: UIAction {
    typealias InputType = DismissUIInput
    typealias PresenterType = UIViewController
}

extension DismissingUIAction {
    public static func perform(context: ActionContext<InputType>, presenter: PresenterType, completion: Completion) -> Completion.Status {
        presenter.dismiss(animated: context.input.animated)
        return completion.completedSync(.successWithFeatureTermination)
    }
}
#endif
