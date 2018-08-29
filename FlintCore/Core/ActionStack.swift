//
//  ActionSequence.swift
//  FlintCore
//
//  Created by Marc Palmer on 16/10/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// An Action Stack is a trail of actions a user has performed from a specific Feature, with
/// sub-stacks created when the user then uses an action from another feature, so each stack
/// can represent a graph of actions broken down by feature.
///
/// Certain actions will "Close" their stack, e.g. a "Close" option on a document editing feature. Some stacks
/// may never be closed however, say a "DrawingFeature" that allows use of many drawing tools. There is no
/// clear end to that except closing the document, an operation on a different feature.
///
/// !!! TODO: Work out what this means for sub-stacks. We want to retain information about what was
/// done in other features, in amongst the current stack's features, but when the stack closes we
/// don't want to lose that history if there was not a "closing" action of the sub stack. Some sub-stacks
/// should be implicitly discarded however - e.g. drawing functions.
///
/// We need reference semantics here because we have parent relationships and navigate the graph.
///
/// !!! TODO: Use LIFOQueue to limit to the number of past items held to avoid blowing/leaking memory over time
public class ActionStack: CustomDebugStringConvertible {
    /// The date and time this stack started.
    public let startDate = Date()
    public let id: String
    public let parent: ActionStack?
    public let feature: FeatureDefinition.Type
    public let sessionName: String
    public var timeIntervalSinceStart: TimeInterval { return -startDate.timeIntervalSinceNow }
    public var timeIntervalToLastEntry: TimeInterval { return entries.last?.startDate.timeIntervalSince(startDate) ?? 0 }
    public let userInitiated: Bool
    
    /// Threadsafe access to the first entry, if any
    public var first: ActionStackEntry? {
        return propertyAccessQueue.sync { entries.first }
    }

    /// - note: Only safe to access from within a `withProperties` block
    private var entries = [ActionStackEntry]()
    
    /// Queue used for threadsafe access to the properties, as the entries are mutable
    private let propertyAccessQueue = DispatchQueue(label: "flint.tools.action-stack")
    
    public init(id: String, sessionName: String, feature: FeatureDefinition.Type, userInitiated: Bool, parent: ActionStack?) {
        self.id = id
        self.sessionName = sessionName
        self.parent = parent
        self.feature = feature
        self.userInitiated = userInitiated
    }
    
    /// Add a new entry to the end of the action stack
    func add(entry: ActionStackEntry) {
        withEntries { _ in
            entries.append(entry)
        }
    }

    /// Use this to access the entries of this stack. Not doing so is not threadsafe.
    public func withEntries<T>(_ block: ([ActionStackEntry]) -> T) -> T {
        let entries = propertyAccessQueue.sync {
            return self.entries
        }
        return block(entries)
    }
    
    public var debugDescription: String {
        let actions: [String] = withEntries { _ in
            return entries.map( { $0.debugDescription } )
        }
        return "Stack \(id) for feature \(feature) in session '\(sessionName), active for \(Int(timeIntervalToLastEntry))': \(actions.joined(separator: ", "))"
    }
}

extension ActionStack {
    func writeHumanReadableDescription(userInitiatedOnly: Bool, using printer: (String) -> Void) {
        let actions: [String] = propertyAccessQueue.sync {
            var filteredEntries = entries
            if userInitiatedOnly {
                filteredEntries = entries.filter { $0.userInitiated }
            }
            return filteredEntries.map( { "\($0.startDate): \($0.debugDescription)" } )
        }
        printer("Stack \(id) for feature \(feature) in session '\(sessionName)':")
        printer(actions.joined(separator: "\n"))
    }
}
