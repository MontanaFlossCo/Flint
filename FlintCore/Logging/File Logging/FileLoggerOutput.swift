//
//  FileLoggerOutput.swift
//  FlintCore
//
//  Created by Marc Palmer on 24/01/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Logging output to persistent files that can be archived using Flint's report gathering.
///
/// - note: Currently does not support maximum log sizes or log file rotation.
public class FileLoggerOutput: LoggerOutput {
    public let nameStem: String
    public let folderName: String
    public let namingStrategy: LogFileNamingStrategy
    public let formattingStrategy: LogEventFormattingStrategy = VerboseLogEventFormatter()

    private let baseURL: URL
    private var currentLogFile: LogFile?

    /// Create a new logger output that writes to files.
    ///
    /// - param appGroupIdentifier: The optional App Group ID to use to store the logs in a shared container
    /// - param name: The file name of the log file (minus path). This will be passed to the naming strategy for inclusion.
    /// - param folderName: The name of the folder in which to put the log file, under the container.
    /// - param namingStrategy: An optional strategy for creating log file names. By default a `TimestampLogFileNamingStrategy` will be used.
    public init(appGroupIdentifier: String?, name: String, folderName: String = "Flint", namingStrategy: LogFileNamingStrategy? = nil) throws {
        self.folderName = folderName
        self.namingStrategy = namingStrategy ?? TimestampLogFileNamingStrategy(namePrefix: name)
        self.nameStem = name
        
        let containerURL: URL
        if let groupID = appGroupIdentifier {
            guard let appGroupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
                fatalError("Couldn't get app group container with ID \(groupID)")
            }
            containerURL = appGroupUrl
        } else {
            containerURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        }
        
        baseURL = containerURL.appendingPathComponent(folderName).appendingPathComponent("Logs")
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
        
        flintInformation("File logs are being written to: \(baseURL.path)")
    }
    
    public func log(event: LogEvent) {
        if currentLogFile == nil {
            openLogFile()
        }
        guard let logFile = currentLogFile else {
            flintBug("Log file is nil")
        }
        if let text = formattingStrategy.format(event) {
            logFile.write(text)
        }
    }
    
    public func copyForArchiving(to path: URL) {
        let urls = logFileURLs()
        for url in urls {
            do {
                try FileManager.default.copyItem(at: url, to: path)
            } catch let e {
                assertionFailure("Could not copy logs: \(e)")
            }
        }
    }
    
    // MARK: Internals

    func logFileURLs() -> [URL] {
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsPackageDescendants])
            return urls
        } catch let e {
            assertionFailure("Could not list log files: \(e)")
            return []
        }
    }
    

    /// Open or create the log file as necessary.
    private func openLogFile() {
        let logUrl = urlForNextLogFile
        let exists = FileManager.default.fileExists(atPath: logUrl.path)
        do {
            currentLogFile = try LogFile(filename: logUrl, createNew: !exists)
        } catch let e {
            flintBug("Could not create log file: \(e)")
        }
    }
    
    private var urlForNextLogFile: URL {
        let filename = namingStrategy.next()
        guard let escapedFilename = filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            flintBug("Failed to escape filename: \(filename)")
        }
        let logUrl = baseURL.appendingPathComponent(escapedFilename, isDirectory: false)
        return logUrl
    }
}
