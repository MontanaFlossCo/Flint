//
//  ActionStackTracker.swift
//  FlintCore
//
//  Created by Marc Palmer on 23/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This tracker maintains the list of active Action Stacks across all ActionSession(s).
///
/// It is responsible for vending new stacks when required, or existing ones that are not closed.
public class ActionStackTracker: DebugReportable {
    public static let instance = ActionStackTracker()

    private let propertyAccessQueue = DispatchQueue(label: "tools.flint.ActionStackTracker")
    private var currentSequenceID: UInt = 0

    /// !!! TODO: Change this to a dictionary keyed on Feature?
    private var actionStacks = [ActionStack]()

    private init() {
        DebugReporting.add(self)
    }
    
    deinit {
        DebugReporting.remove(self)
    }
    
    /// Returns a safe copy of all the currently open Action Stacks
    public func allActionStacks() -> [ActionStack] {
        return propertyAccessQueue.sync { actionStacks }
    }
    
    /// Returns a safe copy of all the currently open Action Stacks for the given session
    public func allActionStacks(in session: ActionSession) -> [ActionStack] {
        return propertyAccessQueue.sync {
            return actionStacks.filter { $0.sessionName == session.name }
        }
    }

    /// Returns the existing Action Stack for a given feature (in any session), or nil if there isn't one
    public func actionStack(for feature: FeatureDefinition.Type) -> ActionStack? {
        return propertyAccessQueue.sync {
            return actionStacks.first(where: {
                $0.feature == feature
            })
        }
    }
    
    /// Find the existing Action Stack for the given feature, or create a new one.
    ///
    /// Action Stacks are scoped to individual features, and are not inherited by sub-features.
    /// So for feature X with subfeature A, if an action of X is performed and also an action of A is performed,
    /// if they are non-terminating actions you will have two concurrent stacks, on for X and one for A.
    func findOrCreateActionStack(for feature: FeatureDefinition.Type, in session: ActionSession, userInitiated: Bool) -> ActionStack {
        return propertyAccessQueue.sync {
            var actionStack = actionStacks.first(where: { $0.feature == feature })
            if actionStack == nil {
                let parentStack = actionStacks.last
                let nextSequenceID = currentSequenceID + 1
                currentSequenceID = nextSequenceID
                actionStack = ActionStack(id: String(nextSequenceID),
                                                  sessionName: session.name,
                                                  feature: feature,
                                                  userInitiated: userInitiated,
                                                  parent: parentStack)
                if let parent = parentStack {
                    parent.add(entry: ActionStackEntry(actionStack!, userInitiated: session.userInitiatedActions))
                }
                actionStacks.append(actionStack!)
            }

            return actionStack!
        }
    }

    /// Terminates an action sequence, removing it from the list of active stacks
    func terminate<FeatureType, ActionType>(_ stack: ActionStack, actionRequest: ActionRequest<FeatureType, ActionType>) {
        propertyAccessQueue.sync {
            if let index = actionStacks.index(where: { $0 === stack }) {
                actionStacks.remove(at: index)
                actionRequest.context.logs.development?.debug("End of Action Stack")
            }
        }
    }
    
    /// Debug function to output the state of the active stacks
    public func dumpActionStacks() -> String {
        func _renderStack(_ stack: ActionStack, _ prefix: String = "") -> String {
            let entryDescriptions: [String] = stack.withEntries { entries in
                return entries.map {
                    switch $0.details {
                        case .action(let name, let source, let input): return "Action \(name) via \(source) with input: (\(input ?? ""))"
                        case .substack(let stack): return "Sub-stack \(stack.id)"
                    }
                }
            }
            let entryText = entryDescriptions.joined(separator: "\n")
            var result = "\(stack.debugDescription):\n\(entryText)\n"
            let subStacks = actionStacks.filter { $0.parent === stack }
            result.append(subStacks.map( { _renderStack($0, " ↪️") }).joined(separator: "\n"))
            return result
        }
        return propertyAccessQueue.sync {
            let rootStacks = actionStacks.filter { $0.parent == nil }
            var result = "Current Action Stacks:\n"
            result.append(rootStacks.map( { _renderStack($0) }).joined(separator: "\n"))
            return result
        }
    }
    
}

extension ActionStackTracker {
    public func writeHumanReadableReport(to data: inout Data, userInitiatedOnly: Bool) {
        func _print(_ text: String) {
            data.append(contentsOf: text.utf8)
            data.append(contentsOf: "\n".utf8)
        }
        _print("Active Action Stacks")
        _print("========================\n")
        let stacks = ActionStackTracker.instance.allActionStacks()
        for stack in stacks {
            stack.writeHumanReadableDescription(userInitiatedOnly: userInitiatedOnly, using: _print)
            _print("")
        }
    }

    public func writeJSONReport(to data: inout Data, userInitiatedOnly: Bool) {
        let stacks = ActionStackTracker.instance.allActionStacks()

        var jsonStacks = [[String:Any?]]()
        for stack in stacks {
            jsonStacks.append(stack.jsonRepresentation)
        }

        let jsonPayload: [String:Any?] = ["stacks": jsonStacks]
        
        if let results = try? JSONSerialization.data(withJSONObject: jsonPayload, options: [.prettyPrinted]) {
            data.append(results)
        } else {
            flintBug("Could not generate JSON report")
        }
    }
}

public extension ActionStackTracker {
    public func copyReport(to path: URL, options: Set<DebugReportOptions>) {
        var data = Data()
        let userInitiatedOnly = options.contains(.userInitiatedOnly)
        if options.contains(.machineReadableFormat) {
            writeJSONReport(to: &data, userInitiatedOnly: userInitiatedOnly)
        } else {
            writeHumanReadableReport(to: &data, userInitiatedOnly: userInitiatedOnly)
        }
        do {
            try data.write(to: path.appendingPathComponent("action_stacks.txt"))
        } catch let e {
            FlintInternal.logger?.error("Could not write action_stacks.txt: \(e)")
            // Carry on, as maybe logs were useful
        }
    }
}
