//
//  FocusLogDataAccessFeature.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 06/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import FlintCore

/// Provides the data for a UI that shows Focus Logs
final public class FocusLogDataAccessFeature: ConditionalFeature {
    public static var description: String = "Provides access to the Focus logs for presenting in a UI"

    public static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.runtimeEnabled()
    }

    public static var isEnabled: Bool?
    
    public static let loadInitialResults = action(LoadInitialResultsAction.self)
    public static let loadMoreResults = action(LoadMoreResultsAction.self)

    public static func prepare(actions: FeatureActionsBuilder) {
        isEnabled = FocusFeature.isEnabled
        
        actions.declare(loadInitialResults)
        actions.declare(loadMoreResults)
    }

    // MARK: Actions
    
    final public class LoadInitialResultsAction: Action {
        public typealias InputType = Int
        public typealias PresenterType = FocusLogPresenter
        
        public static var description: String = "Loads the initial results from the Focus Log"

        public static var hideFromTimeline: Bool = true
        
        public static func perform(context: ActionContext<InputType>, presenter: PresenterType, completion: @escaping (ActionPerformOutcome) -> Void) {
            guard let logs = FocusFeature.dependencies.developmentFocusLogging else {
                completion(.success(closeActionStack: true))
                return
            }

            let focusLogController = TimeOrderedResultsController(dataSource: logs.history, delegate: presenter, delegateQueue: .main)
            presenter.focusLogController = focusLogController
            focusLogController.loadMore(count: context.input)

            completion(.success(closeActionStack: false))
        }
    }

    final public class LoadMoreResultsAction: Action {
        public typealias InputType = Int
        public typealias PresenterType = FocusLogPresenter
        
        public static var description: String = "Loads another page of results from the Focus Log"

        public static var hideFromTimeline: Bool = true

        public static let defaultExtraPageCount = 10
        
        public static func perform(context: ActionContext<InputType>, presenter: PresenterType, completion: @escaping (ActionPerformOutcome) -> Void) {
            guard let focusLogController = presenter.focusLogController else {
                flintBug("Initial results have not been loaded")
            }
            focusLogController.loadMore(count: context.input)
            completion(.success(closeActionStack: false))
        }
    }

}

/// The FocusLogPresenter has to be able to store the controller created when loading initial results,
/// so that the other actions can operate on that state retained by the presenter.
public protocol FocusLogPresenter: TimeOrderedResultsControllerDelegate  {
    var focusLogController: TimeOrderedResultsController? { get set }
}

