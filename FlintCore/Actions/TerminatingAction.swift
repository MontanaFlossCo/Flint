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
///
/// Conforming to this protocol is useful for "done" type Actions that you want to participate
/// in standard Action patterns, but do not actually perform any code.
public protocol TerminatingAction: Action {
}

extension TerminatingAction {
    public static func perform(context: ActionContext<InputType>, presenter: PresenterType, completion: Completion) -> Completion.Status {
        return completion.completedSync(.successWithFeatureTermination)
    }
}
