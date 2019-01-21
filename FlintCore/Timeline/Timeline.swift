//
//  Timeline.swift
//  FlintCore
//
//  Created by Marc Palmer on 07/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// An action dispatch observer that will collect a rolling buffer of N action events, and can notify observers when these entries
/// change. Action requests are converted into audit entries that are immutable, so the values of action state
/// and other information are captured at the point of the action occurring, allow you to see changes in the action state
/// over time through the log.
///
/// This is a high level flattened breadcrumb trail of what the user has done in the app, purely in action terms. No other
/// logging is included, so this is suitable for inclusion in crash reports and support requests.
///
/// Use this to capture the history of what the user has done. You can use `Flint.quickSetup` or manually add this observer
/// with:
///
/// ```
/// Flint.dispatcher.add(observer: TimelineDispatchObserver(maxEntries: 50))
/// ```
///
/// - see: `Flint.quickSetup` which will add this dispatcher for you automatically.
public class Timeline: ActionDispatchObserver, DebugReportable {
    public static let instance: Timeline = Timeline()
    public private(set) var entries: LIFOArrayQueueDataSource<TimelineEntry>

    public init(maxEntries: Int = 100) {
        entries = LIFOArrayQueueDataSource<TimelineEntry>(maxCount: maxEntries)

        DebugReporting.add(self)
    }
    
    // MARK: Observing the action dispatcher
    
    public func actionWillBegin<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>) {
        guard !ActionType.hideFromTimeline else {
            return
        }
        guard !(FocusFeature.dependencies.focusSelection?.shouldSuppress(feature: FeatureType.self) == true) else {
            return
        }
        let entry = TimelineEntry(sequenceID: request.uniqueID,
                                  userInitiated: request.userInitiated,
                                  source: request.source,
                                  date: Date(),
                                  sessionName: request.sessionName,
                                  feature: FeatureType.self,
                                  actionName: ActionType.name,
                                  inputDescription: request.context.input.loggingDescription,
                                  inputInfo: request.context.input.loggingInfo)
        entries.append(entry)
    }
    
    public func actionDidComplete<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>, outcome: ActionPerformOutcome) {
        guard !ActionType.hideFromTimeline else {
            return
        }
        guard !(FocusFeature.dependencies.focusSelection?.shouldSuppress(feature: FeatureType.self) == true) else {
            return
        }
        let entry = TimelineEntry(sequenceID: request.uniqueID,
                                  userInitiated: request.userInitiated,
                                  source: request.source,
                                  date: Date(),
                                  sessionName: request.sessionName,
                                  feature: FeatureType.self,
                                  actionName: ActionType.name,
                                  inputDescription: request.context.input.loggingDescription,
                                  inputInfo: request.context.input.loggingInfo,
                                  outcome: outcome.simplifiedOutcome)
        entries.append(entry)
    }
    
}

extension Timeline {
    func writeHumanReadableReport(to data: inout Data, userInitiatedOnly: Bool) {
        let timeline = self.entries.snapshot()
        data.append(contentsOf: "Timeline\n".utf8)
        data.append(contentsOf: "\(Date())\n".utf8)
        
        for entry in timeline {
            if userInitiatedOnly && !entry.userInitiated {
                continue
            }
            data.append(contentsOf: entry.description.utf8)
            data.append(contentsOf: "\n".utf8)
        }
    }

    func writeJSONReport(to data: inout Data, userInitiatedOnly: Bool) {
        let timeline = self.entries.snapshot()
        let includedEntries = userInitiatedOnly ? timeline.filter({ $0.userInitiated }) : timeline
        let jsonEntries = includedEntries.map { $0.jsonRepresentation }
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonEntries, options: .prettyPrinted)
        data.append(jsonData)
    }
}

extension Timeline {
    public func copyReport(to path: URL, options: Set<DebugReportOptions>) {
        var data = Data()

        let userInitiatedOnly = options.contains(.userInitiatedOnly)
        let machineReadable = options.contains(.machineReadableFormat)
        if machineReadable {
            writeJSONReport(to: &data, userInitiatedOnly: userInitiatedOnly)
        } else {
            writeHumanReadableReport(to: &data, userInitiatedOnly: userInitiatedOnly)
        }
        let filename = machineReadable ? "timeline.json" : "timeline.txt"
        do {
            try data.write(to: path.appendingPathComponent(filename))
        } catch let e {
            FlintInternal.logger?.error("Could not write \(filename): \(e)")
            // Carry on, as maybe logs were useful
        }
    }
}


