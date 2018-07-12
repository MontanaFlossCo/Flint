//
//  TimelineEntry.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 16/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Timeline Entries encapsulate all the lightweight representations of properties related to an action event to be
/// stored in a timeline without any references to the original data. This is to prevent memory usage spiralling out of
/// control while the app is running.
///
/// !!! TODO: Remove @objc and change entry to `struct` when Swift bug SR-6039/SR-55 is fixed.
/// - see: https://bugs.swift.org/browse/SR-55
@objc public class TimelineEntry: NSObject, UniquelyIdentifiable {

    /// The kind of event. We can record both the start and completion of actions
    public enum Kind {
        case begin
        case complete
    }

    public let kind: Kind
    
    /// An incrementing ID for entries. Supports overflow, so it only unique when combined with the current date/time
    public let sequenceID: UInt
    
    /// A unique ID for the entry
    public var uniqueID: String { return "\(date.timeIntervalSince1970)-\(sequenceID)" }
    
    /// Indicates whether or not the action was performed directly by a user, or automatically by code
    public let userInitiated: Bool
    
    /// An indication of the source of the action. User initiated actions can come from multiple sources e.g.
    /// UI interactions or asking the system to open a URL
    public let source: ActionSource
    
    /// The date/time the event occurred
    public let date: Date
    
    /// The feature in which the action was invoked
    public let feature: FeatureDefinition.Type
    
    /// The session name in which the action was performed
    public let sessionName: String
    
    /// The name of the action
    public let actionName: String
    
    /// The human-friendly description of the input to the action
    public let inputDescription: String?
    
    /// The detailed debug description of the input to the action
    public let inputInfo: [String:Any]?

    /// The outcome of the action. This is nil unless `kind` is `.complete`.
    public let outcome: ActionOutcome?

    convenience init(sequenceID: UInt, userInitiated: Bool, source: ActionSource, date: Date, sessionName: String, feature: FeatureDefinition.Type, actionName: String, inputDescription: String?, inputInfo: [String:String]?) {
        self.init(kind: .begin, sequenceID: sequenceID, userInitiated: userInitiated, source: source, date: date, sessionName: sessionName, feature: feature, actionName: actionName, inputDescription: inputDescription, inputInfo: inputInfo, outcome: nil)
    }
    
    convenience init(sequenceID: UInt, userInitiated: Bool, source: ActionSource, date: Date, sessionName: String, feature: FeatureDefinition.Type, actionName: String, inputDescription: String?, inputInfo: [String:String]?, outcome: ActionOutcome) {
        self.init(kind: .complete, sequenceID: sequenceID, userInitiated: userInitiated, source: source, date: date, sessionName: sessionName, feature: feature, actionName: actionName, inputDescription: inputDescription, inputInfo: inputInfo, outcome: outcome)
    }
    
    private init(kind: Kind, sequenceID: UInt, userInitiated: Bool, source: ActionSource, date: Date, sessionName: String, feature: FeatureDefinition.Type, actionName: String, inputDescription: String?, inputInfo: [String:String]?, outcome: ActionOutcome?) {
        self.userInitiated = userInitiated
        self.source = source
        self.kind = kind
        self.sequenceID = sequenceID
        self.date = date
        self.sessionName = sessionName
        self.feature = feature
        self.actionName = actionName
        self.inputDescription = inputDescription
        self.inputInfo = inputInfo
        self.outcome = outcome
    }
    
    public override var description: String {
        var result = "\(date): \(uniqueID) - "
        switch kind {
            case .begin: result.append(userInitiated ? "User began " : "Began ")
            case .complete: result.append(userInitiated ? "User completed ": "Completed ")
        }
        result.append("\"\(actionName) of \(feature.identifier)\" from source \(source)")
        if let inputDescription = inputDescription {
            result.append("\n  Input: '\(inputDescription)'")
        }
        if let outcome = outcome {
            result.append("\n  Outcome: \(outcome)")
        }
        result.append(" of \(feature) in session '\(sessionName)'")
        return result
    }
}
