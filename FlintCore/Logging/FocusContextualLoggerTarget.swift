//
//  DefaultContextualLoggerTarget.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 19/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The contextual logger target implementation used by default, to support the Focus feature of Flint.
///
/// This will use the current `FocusSelection` to work out whether or not Focus is in effect, and if it is
/// whether or not events should be logged.
///
/// When Focus is active, it will also drop the effective log level to `debug` so that everything related to your
/// focused areas is output.
///
/// Then focus is not active, a standed log level threshold is applied.
public class FocusContextualLoggerTarget: ContextualLoggerTarget {
    public var level: LoggerLevel = .debug
    
    let output: AggregatingLoggerOutput
    private var logLevelsByTopic: [TopicPath:LoggerLevel] = [:]
    private let queue = DispatchQueue(label: "tools.flint.contextual-logger-target", qos: .background)
    private var sequenceID: UInt = 0
    
    init(output: AggregatingLoggerOutput) {
        self.output = output
    }

    public func setLevel(for topic: TopicPath, to level: LoggerLevel?) {
        queue.sync {
            if let level = level {
                logLevelsByTopic[topic] = level
            } else {
                logLevelsByTopic.removeValue(forKey: topic)
            }
        }
    }
    
    public func log(level: LoggerLevel, context: LogEventContext, content: @escaping @autoclosure () -> String) {
        queue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            // If there is no focus active, or there is focus and this topic is within the area of interest, log it.
            //
            // We fake the threshold as "debug" if items are in the current focus, and anything not focused becomes threshold `.none`
            let effectiveThreshold: LoggerLevel
            if let focusSelection = FocusFeature.dependencies.focusSelection, focusSelection.isActive {
                effectiveThreshold = focusSelection.isFocused(context.topicPath) ? .debug : .none
            } else {
                effectiveThreshold = strongSelf.topicLevel(for: context.topicPath) ?? strongSelf.level
            }
            guard effectiveThreshold >= level else {
                return
            }

            // Support overflow here without failing
            strongSelf.sequenceID = strongSelf.sequenceID &+ 1
            
            let event = LogEvent(date: Date(),
                                 sequenceID: strongSelf.sequenceID,
                                 level: level,
                                 context: context,
                                 text: content())
            
            strongSelf.output.log(event: event)
        }
    }
    
    func add(output: LoggerOutput) {
        queue.sync {
            self.output.add(output: output)
        }
    }
    
    private func topicLevel(for topicPath: TopicPath) -> LoggerLevel? {
        if let explicitLevel = logLevelsByTopic[topicPath] {
            return explicitLevel
        } else {
            /// !!! TODO: This is inefficient, at most we should explicitly look up each ancestor path
            let inheritedLevel = logLevelsByTopic.first { key, _ in key.matches(topicPath) }
            return inheritedLevel?.value
        }
    }
}
