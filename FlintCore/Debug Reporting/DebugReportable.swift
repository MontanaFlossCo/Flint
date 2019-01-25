//
//  DebugReportable.swift
//  FlintCore
//
//  Created by Marc Palmer on 28/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Classes conforming to this protocol can provide debug reports when `Flint.gatherReportZip` is called.
///
/// Use in apps to expose app-specific debug information that may be useful for troubleshooting.
///
/// - see: `DebugReporting.add(:)` for registering your own reportable objet to be included.
public protocol DebugReportable: AnyObject {
    func copyReport(to path: URL, options: Set<DebugReportOption>) throws
}

/// Options for the report export.
public enum DebugReportOption {
    /// Specify this option to only include events resulting from an action that the user directly initiated, as specified
    /// in the `userInitiated` property of the `ActionContext`. This will filter out any programmatically triggered events,
    /// such as data or time event-based subsystems.
    case userInitiatedOnly
    
    /// Specify this option to output the reports in JSON format for automated processing.
    case machineReadableFormat
}

