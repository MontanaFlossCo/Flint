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
    
    public static var availability: FeatureAvailability = .runtimeEnabled
    
    /// Set this to `false` at runtime to disable the Focus feature completely
    public static var enabled = true

    public static var defaultMaxLogEvents: Int = 1000
    
    public struct Dependencies {
        public let developmentFocusLogging: FocusLogging?
        public let productionFocusLogging: FocusLogging?
        public let focusSelection: FocusSelection?

        fileprivate init() {
            developmentFocusLogging = nil
            productionFocusLogging = nil
            focusSelection = nil
        }
        
        fileprivate init(developmentFocusLogging: FocusLogging?, productionFocusLogging: FocusLogging?, focusSelection: FocusSelection?) {
            self.developmentFocusLogging = developmentFocusLogging
            self.productionFocusLogging = productionFocusLogging
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
            var developmentLogging: FocusLogging?
            var productionLogging: FocusLogging?
            if let development = Logging.development {
                let developmentFocusLogging = FocusLogging(maxCount: defaultMaxLogEvents)
                development.add(output: developmentFocusLogging)
                developmentLogging = developmentFocusLogging
            }
            if let production = Logging.production {
                let productionFocusLogging = FocusLogging(maxCount: defaultMaxLogEvents)
                production.add(output: productionFocusLogging)
                productionLogging = productionFocusLogging
            }
            dependencies = Dependencies(
                developmentFocusLogging: developmentLogging,
                productionFocusLogging: productionLogging,
                focusSelection: DefaultFocusSelection())
            
        }
    }
}

final public class FocusAction: Action {
    public typealias InputType = FocusArea
    public typealias PresenterType = NoPresenter

    public static func perform(with context: ActionContext<InputType>, using presenter: PresenterType, completion: @escaping (ActionPerformOutcome) -> Void) {
        FocusFeature.dependencies.focusSelection?.focus(context.input.topicPath)
        
        completion(.success(closeActionStack: true))
    }
}

final public class DefocusAction: Action {
    public typealias InputType = FocusArea
    public typealias PresenterType = NoPresenter

    public static func perform(with context: ActionContext<InputType>, using presenter: PresenterType, completion: @escaping (ActionPerformOutcome) -> Void) {
        FocusFeature.dependencies.focusSelection?.defocus(context.input.topicPath)

        completion(.success(closeActionStack: true))
    }
}

final public class ResetFocusAction: Action {
    public typealias InputType = NoInput
    public typealias PresenterType = NoPresenter

    public static func perform(with context: ActionContext<InputType>, using presenter: PresenterType, completion: @escaping (ActionPerformOutcome) -> Void) {
        FocusFeature.dependencies.focusSelection?.reset()

        completion(.success(closeActionStack: true))
    }
}
