//
//  ResignCurrentActivityAction.swift
//  FlintCore
//
//  Created by Marc Palmer on 06/05/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Resigns the last action activity that was made current
final public class ResignCurrentActivityAction: UIAction {
    public typealias InputType = NoInput
    public typealias PresenterType = NoPresenter
    
    public static var description: String = "Resign the last NSUserActivity that was auto-registered for an action"

    public static func perform(context: ActionContext<NoInput>, presenter: PresenterType, completion: Action.Completion) -> Action.Completion.Status {
        PublishCurrentActionActivityAction.currentActivity?.resignCurrent()
        return completion.completedSync(.success)
    }
}
