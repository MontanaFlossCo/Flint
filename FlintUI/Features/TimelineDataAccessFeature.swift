//
//  TimelineDataAccessFeature.swift
//  FlintUI
//
//  Created by Marc Palmer on 06/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import FlintCore

/// A feature that provides access to the Timeline for presenting in a UI
final public class TimelineDataAccessFeature: ConditionalFeature {
    public static var description: String = "Provides access to the timeline of actions for debugging and reporting"

    public static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.runtimeEnabled()
    }

    public static var isEnabled: Bool?
    
    public static let loadInitialResults = action(LoadInitialResultsAction.self)
    public static let loadMoreResults = action(LoadMoreResultsAction.self)

    public static func prepare(actions: FeatureActionsBuilder) {
        isEnabled = TimelineFeature.isEnabled
        
        actions.declare(loadInitialResults)
        actions.declare(loadMoreResults)
    }

    // MARK: Actions
        
    final public class LoadInitialResultsAction: Action {
        public typealias InputType = Int
        public typealias PresenterType = TimelinePresenter
        
        public static var description: String = "Loads the initial page of results from the timeline"

        public static var hideFromTimeline: Bool = true

        public static func perform(with context: ActionContext<InputType>, using presenter: PresenterType, completion: @escaping (ActionPerformOutcome) -> Void) {
            let timeline = Timeline.instance
            let timelineController = TimeOrderedResultsController(dataSource: timeline.entries, delegate: presenter, delegateQueue: .main)
            presenter.timelineController = timelineController
            timelineController.loadMore(count: context.input)
            completion(.success(closeActionStack: false))
        }
    }

    final public class LoadMoreResultsAction: Action {
        public typealias InputType = Int
        public typealias PresenterType = TimelinePresenter
        
        public static var description: String = "Loads more from the timeline, starting from the oldest item loaded"

        public static var hideFromTimeline: Bool = true

        public static let defaultExtraPageCount = 10
        
        public static func perform(with context: ActionContext<InputType>, using presenter: PresenterType, completion: @escaping (ActionPerformOutcome) -> Void) {
            guard let timelineController = presenter.timelineController else {
                preconditionFailure("Initial results have not been loaded")
            }
            timelineController.loadMore(count: context.input)
            completion(.success(closeActionStack: false))
        }
    }
}

/// The TimelinePresenter has to be able to store the controller created when loading initial results,
/// so that the other actions can operate on that state retained by the presenter.
///
/// This means the presenter owns the timeline state for its UI
public protocol TimelinePresenter: TimeOrderedResultsControllerDelegate  {
    var timelineController: TimeOrderedResultsController? { get set }
}
