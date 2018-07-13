//
//  FocusLogViewController.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 31/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import UIKit
import FlintCore

public class FocusLogViewController: UITableViewController, FocusLogPresenter {
 
    var items = [LogEvent]()
    
    public static func instantiate() -> FocusLogViewController {
        let storyboard = UIStoryboard(name: "FlintUI", bundle: Bundle(for: FocusLogViewController.self))
        let viewController = storyboard.instantiateViewController(withIdentifier: "FocusLog") as! FocusLogViewController
        return viewController
    }
    
    public var focusLogController: TimeOrderedResultsController?
    var firstDataReceived = false
    var selectedEntry: (Int, LogEvent)?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.clearsSelectionOnViewWillAppear = false
        
        navigationItem.title = "Focus Logs"
        if navigationController?.viewControllers.first == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissLogs))
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareLogs))

        guard let request = FocusLogDataAccessFeature.request(FocusLogDataAccessFeature.loadInitialResults) else {
            let alertController = UIAlertController(title: "Focus Logs not available", message: "The Focus feature is not enabled. Set FocusFeature.isAvailable = true at startup to enable Focus.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true)
            return
        }
        request.perform(input: 20, presenter: self)
    }
    
    // MARK: Table View
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count + 1
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.item < items.count else {
            return tableView.dequeueReusableCell(withIdentifier: "LoadMore", for: indexPath)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogEntry", for: indexPath)
        let item = items[indexPath.row]
        var args: String = ""
        if let foundArguments = item.context.arguments {
            let description = foundArguments.description
            if description.count > 0 {
                args = " with input \(description)"
            }
        }
        cell.textLabel?.text = "\(item.level): \(item.context.topicPath.path.last!) - \(item.text)\(args)"
        cell.detailTextLabel?.text = "\(Formatters.detailedDate(from: item.date)) - \(item.context.topicPath)"
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard indexPath.item < items.count else {
            guard let request = FocusLogDataAccessFeature.request(FocusLogDataAccessFeature.loadMoreResults) else {
                flintUsageError("This UI requires that FocusLogFeature is enabled. Set FocusLogFeature.isAvailable = true at startup.")
            }
            request.perform(input: 20, presenter: self)
            return nil
        }
        let entry = items[indexPath.item]
        selectedEntry = (indexPath.item, entry)
        return indexPath
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry = items[indexPath.item]
        let alertController = UIAlertController(title: "Log Event", message: String(reflecting: entry), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true)
    }
    
    // MARK: Outlets and actions
    
    @objc public func shareLogs() {
        let url = DebugReporting.gatherReportZip()
        let shareViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        shareViewController.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: url)
        }
        present(shareViewController, animated: true)
    }

    @objc public func dismissLogs() {
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: TimeOrderedResultsControllerDelegate

extension FocusLogViewController {
    public func newResultsInserted(items: [Any]) {
        let entries = items as! [LogEvent]
        let indexes = (0..<entries.count).indices.map { IndexPath(row: $0, section: 0) }
        
        // Update the model
        self.items.insert(contentsOf: entries, at: 0)
        
        tableView.insertRows(at: indexes, with: firstDataReceived ? .automatic : .none)
        firstDataReceived = true
    }
    
    public func oldResultsLoaded(items: [Any]) {
        let entries = items as! [LogEvent]
        let indexes = (0..<entries.count).indices.map { IndexPath(row: self.items.count + $0, section: 0) }
        
        // Update the model
        self.items.append(contentsOf: entries)
        
        if firstDataReceived {
            tableView.insertRows(at: indexes, with: firstDataReceived ? .automatic : .none)
        }
        firstDataReceived = true
    }
}
