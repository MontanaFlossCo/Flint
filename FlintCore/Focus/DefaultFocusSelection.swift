//
//  DefaultFocusSelection.swift
//  FlintCore
//
//  Created by Marc Palmer on 06/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This is the default implementation of focus selection.
///
/// This will change the development and production logging, and the Timeline to log only items
/// related to the focused features. Call `reset` to revert to recording full Timeline and your standard logging levels.
///
/// - note: Changing and querying the focus selection is threadsafe, you may call from any queue at runtime or in LLDB.
class DefaultFocusSelection: FocusSelection, CustomDebugStringConvertible {
    private let updateQueue: DispatchQueue = DispatchQueue(label: "tools.flint.default-focus-selection")
    
    /// The set of currently focused topics.
    /// - note: The convoluted lazy init here is to avoid the thread sanitizer choking on something that is not a problem.
    private var focusedTopics: Set<TopicPath>?

    var isActive: Bool {
        return updateQueue.sync {
            let haveTopics = (focusedTopics?.count ?? 0) > 0
            return haveTopics
        }
    }

    func shouldSuppress(_ topicPath: TopicPath) -> Bool {
        return updateQueue.sync {
            let haveTopics = (focusedTopics?.count ?? 0) > 0
            return haveTopics && !_isFocused(topicPath)
        }
    }

    func isFocused(_ topicPath: TopicPath) -> Bool {
        // Sync only once on the whole operation
        return updateQueue.sync {
            return _isFocused(topicPath)
        }
    }
    
    /// Internal function to avoid multiple `sync` calls.
    /// - note: Must be called only from the `updateQueue`
    private func _isFocused(_ topicPath: TopicPath) -> Bool {
        let found = (focusedTopics?.contains(topicPath)) ?? false
        if found {
            return true
        } else {
            // See if any of the ancestores are focused
            if let parent = topicPath.parentPath() {
                return _isFocused(parent)
            } else {
                return false
            }
        }
    }

    /// Called to add a feature to the focus selection
    func focus(_ topicPath: TopicPath) {
        updateQueue.sync {
            if focusedTopics == nil {
                focusedTopics = []
            }
            let _ = focusedTopics?.insert(topicPath)
        }
    }
    
    /// Called to add a feature to the focus selection
    func defocus(_ topicPath: TopicPath) {
        updateQueue.sync {
            let _ = focusedTopics?.remove(topicPath)
        }
    }
    
    func reset() {
        updateQueue.sync {
            focusedTopics = nil
        }
    }
    
    var debugDescription: String {
        let focusedTopics = updateQueue.sync {
            return self.focusedTopics
        }

        guard let topics = focusedTopics else {
            return "DefaultFocusSelection: nothing is in focus"
        }
        let focusedTopicDescriptions = Array(topics).map( { String(reflecting: $0) } ).joined(separator: ", ")
        return "DefaultFocusSelection: \(focusedTopicDescriptions)"
    }
}
