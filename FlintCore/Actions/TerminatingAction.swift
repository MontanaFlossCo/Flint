//
//  TerminatingAction.swift
//  FlintCore
//
//  Created by Marc Palmer on 20/02/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// An action that performs no work except successfully completing with feature termination.
///
/// Actions adopting this protocol will not need to provide a `perform` implementation.
public protocol TerminatingAction: Action {
}

extension TerminatingAction {
    public static func perform(context: ActionContext<InputType>, presenter: PresenterType, completion: Completion) -> Completion.Status {
        return completion.completedSync(.successWithFeatureTermination)
    }
}

#if os(iOS)
public struct DismissInput: FlintLoggable {
    public let animated: Bool
    
    public static func animated(_ animated: Bool) -> DismissInput {
        return DismissInput(animated: animated)
    }
}

public protocol DismissingUIAction: UIAction {
    typealias InputType = DismissInput
    typealias PresenterType = UIViewController
}

extension DismissingUIAction {
    public static func perform(context: ActionContext<InputType>, presenter: PresenterType, completion: Completion) -> Completion.Status {
        presenter.dismiss(animated: context.input.animated)
        return completion.completedSync(.successWithFeatureTermination)
    }
}
#endif
