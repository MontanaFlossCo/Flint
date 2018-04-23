//
//  DebugReporting.swift
//  FlintCore
//
//  Created by Marc Palmer on 28/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import ZIPFoundation

/// A class for managing the debug reporting options of Flint.
///
/// With this class you can generate a debug report ZIP containing all the reports from various subsystems in Flint
/// and also your app.
///
/// Flint's internal features are automatically registered with DebugReporting, but if you need to add any other
/// data to debug reports you can do so by creating your own object that conforms to `DebugReportable` and
/// register it here with `DebugReporting.add(yourReportableThing)`.
public class DebugReporting {
    private static var reportables = [DebugReportable]()
    private static let updateQueue = DispatchQueue(label: "tools.flint.DebugReporting")

    /// Add a new reportable that will be included when generating reports
    public static func add(_ reportable: DebugReportable) {
        updateQueue.sync {
            reportables.append(reportable)
        }
    }

    /// Remove a reportable that will no longer be included when generating reports
    public static func remove(_ reportable: DebugReportable) {
        updateQueue.sync {
            if let index = reportables.index(where: { $0 === reportable }) {
                reportables.remove(at: index)
            }
        }
    }

    /// Call to iterate over every reportable that has been registered
    public static func eachReportable(_ block: (_ reportable: DebugReportable) -> Void) {
        let reportables = updateQueue.sync { return self.reportables }
        reportables.forEach(block)
    }
    
    /// Called to generate a ZIP containing the reports from all reportables, stored in a temporary location.
    ///
    /// The caller is reponsible for removing the file to free space. The file is in a temporary location but
    /// it is undefined when that will be cleared out.
    public static func gatherReportZip() -> URL {
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let baseURL = tempDirectoryURL.appendingPathComponent("flint-report", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            FlintInternal.logger?.error("Could not generate report, unable to create temp dir at \(baseURL)")
        }
        let filesURL = baseURL.appendingPathComponent("contents", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: filesURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            FlintInternal.logger?.error("Could not generate report, unable to create contents dir at \(baseURL)")
        }

        eachReportable { reportable in
            FlintInternal.logger?.info("Generating report for \(reportable)")
            do {
                try reportable.copyReport(to: filesURL, options: [.machineReadableFormat])
            } catch {
                FlintInternal.logger?.error("Could not write report for \(reportable)")
            }
        }
        
        // 3. Zip the lot up
        let zipURL = baseURL.appendingPathComponent("report.zip")
        try? FileManager.default.removeItem(at: zipURL)
        FlintInternal.logger?.info("Zipping report at \(zipURL)")
        try! FileManager.default.zipItem(at: filesURL, to: zipURL)
        return zipURL
    }
}
