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
    private var focusedTopics: Set<TopicPath> = []
    
    private let updateQueue = DispatchQueue(label: "tools.flint.default-focus-selection")
    
    var active: Bool {
        return updateQueue.sync { focusedTopics.count > 0 }
    }

    func shouldSuppress(_ topicPath: TopicPath) -> Bool {
        return updateQueue.sync {
            return focusedTopics.count > 0 && !_isFocused(topicPath)
        }
    }

    func isFocused(_ topicPath: TopicPath) -> Bool {
        // Sync only once on the whole operation
        return updateQueue.sync { return _isFocused(topicPath) }
    }
    
    /// Internal function to avoid multiple `sync` calls.
    /// - note: Must be called only from the `updateQueue`
    private func _isFocused(_ topicPath: TopicPath) -> Bool {
        let found = focusedTopics.contains(topicPath)
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
            let _ = focusedTopics.insert(topicPath)
        }
    }
    
    /// Called to add a feature to the focus selection
    func defocus(_ topicPath: TopicPath) {
        updateQueue.sync {
            let _ = focusedTopics.remove(topicPath)
        }
    }
    
    func reset() {
        updateQueue.sync {
            focusedTopics.removeAll()
        }
    }
    
    var debugDescription: String {
        if focusedTopics.count == 0 {
            return "DefaultFocusSelection: nothing is in focus"
        } else {
            let focusedTopicDescriptions = Array(focusedTopics).map( { String(reflecting: $0) } ).joined(separator: ", ")
            return "DefaultFocusSelection: \(focusedTopicDescriptions)"
        }
    }
}
