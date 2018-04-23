//
//  LogEventContext.swift
//  FlintCore
//
//  Created by Marc Palmer on 28/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The context for a log event.
///
/// The same context should be used for multiple log events if the context remains the same, e.g. the topic is the same.
public struct LogEventContext {
    /// This identifies the log entry's activity session, e.g. "main" or "background" for a simple app or
    /// for a multi-window or multi-document app, there might be "document1", "document2", "tool-palette"
    public let session: String
    
    /// An identifier for a "thread" of activity that is related, e.g. an ID and description of an action sequence that can
    /// be used to tie together the logging of multiple related actions, such as "345 'Upload a file'" where the text comment
    /// indicates the user's initial intent when the sequence started.
    ///
    /// - see: `ActionStack` for a representation of this.
    public let activity: String
    
    /// The topic path identifies a log topic hierarchically. Filtering of logging can take place by topic, such
    /// that anything matching the patch will be logged and everything else ignored. In Flint this will be
    /// the feature identifier and action name, e.g. `["DocumentManagement", "Editing"]`.
    public let topicPath: TopicPath

    /// Optional dictionary of arguments used when performing the action being logged. Typically the `context` of a
    /// `Action` invocation.
    public let arguments: CustomStringConvertible?

    /// Optional name of a presenter, indicating what UI component is being used to present the activity related to this
    /// log entry.
    public let presenter: String?
}
