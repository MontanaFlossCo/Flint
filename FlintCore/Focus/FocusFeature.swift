//
//  FocusFeaature.swift
//  FlintCore
//
//  Created by Marc Palmer on 26/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The Focus feature provides realtime filtered logging based on Features and Actions.
///
/// Focus is enabled by default. Use the `focus` action to add features to the focus area at runtime.
final public class FocusFeature: ConditionalFeature {
    public static var description: String = "Focus allows the filtering of logs and timelines by Feature and Actions"
    
    public static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.runtimeEnabled()
    }

    /// Set this to `false` at runtime to disable the Focus feature completely
    public static var isEnabled: Bool? = true

    public static var defaultMaxLogEvents: Int = 1000
    
    public struct Dependencies {
        public let focusLoggingHistory: FocusLogging?
        public let focusSelection: FocusSelection?

        fileprivate init() {
            focusLoggingHistory = nil
            focusSelection = nil
        }
        
        fileprivate init(focusLoggingHistory: FocusLogging?, focusSelection: FocusSelection?) {
            self.focusLoggingHistory = focusLoggingHistory
            self.focusSelection = focusSelection
        }
    }
    
    public static private(set) var dependencies = Dependencies()

    /// Perform this action to add a new FocusArea to the current range of focused items
    public static let focus = action(FocusAction.self)

    /// Perform this action to remove a FocusArea drom the current range of focused items
    public static let defocus = action(DefocusAction.self)

    /// Perform this action to reset the focus feature to start tracking everything again
    public static let resetFocus = action(ResetFocusAction.self)

    public static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(focus)
        actions.declare(defocus)
        actions.declare(resetFocus)
        
        /// Wire up the delegate to snoop on log entries
        if isAvailable == true {
            let focusLoggingHistory = FocusLogging(maxCount: defaultMaxLogEvents)
            if let development = Logging.development {
                development.add(output: focusLoggingHistory)
            }
            if let production = Logging.production {
                production.add(output: focusLoggingHistory)
            }
            dependencies = Dependencies(
                focusLoggingHistory: focusLoggingHistory,
                focusSelection: DefaultFocusSelection())
        }
    }
}

final public class FocusAction: UIAction {
    public typealias InputType = FocusArea
    public typealias PresenterType = NoPresenter

    public static func perform(context: ActionContext<InputType>, presenter: PresenterType, completion: Action.Completion) -> Action.Completion.Status {
        FocusFeature.dependencies.focusSelection?.focus(context.input.topicPath)
        
        return completion.completedSync(.successWithFeatureTermination)
    }
}

final public class DefocusAction: UIAction {
    public typealias InputType = FocusArea
    public typealias PresenterType = NoPresenter

    public static func perform(context: ActionContext<InputType>, presenter: PresenterType, completion: Action.Completion) -> Action.Completion.Status {
        FocusFeature.dependencies.focusSelection?.defocus(context.input.topicPath)

        return completion.completedSync(.successWithFeatureTermination)
    }
}

final public class ResetFocusAction: UIAction {
    public typealias InputType = NoInput
    public typealias PresenterType = NoPresenter

    public static func perform(context: ActionContext<InputType>, presenter: PresenterType, completion: Action.Completion) -> Action.Completion.Status {
        FocusFeature.dependencies.focusSelection?.reset()

        return completion.completedSync(.successWithFeatureTermination)
    }
}

