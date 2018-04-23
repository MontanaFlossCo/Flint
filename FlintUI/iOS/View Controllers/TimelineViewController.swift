//
//  ActionLogViewController.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 22/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import UIKit
import FlintCore

public class TimelineViewController: UITableViewController, TimelinePresenter {

    public static func instantiate() -> TimelineViewController {
        let storyboard = UIStoryboard(name: "FlintUI", bundle: Bundle(for: TimelineViewController.self))
        let viewController = storyboard.instantiateViewController(withIdentifier: "Timeline") as! TimelineViewController
        return viewController
    }
    
    private var items = [TimelineEntry]()
    private var selectedEntry: (Int, TimelineEntry)?
    public var timelineController: TimeOrderedResultsController?
    public var firstDataReceived = false

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = false
        
        navigationItem.title = "Timeline"
        if navigationController?.viewControllers.first == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAudit))
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareAudit))

        guard let request = TimelineDataAccessFeature.request(TimelineDataAccessFeature.loadInitialResults) else {
            let alertController = UIAlertController(title: "Timeline not available", message: "The Timeline feature is not enabled. Set TimelineFeature.isAvailable = true at startup to enable Timeline.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true)
            return
        }
        request.perform(using: self, with: 20)
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Table view data source

    override public func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return items.count + 1
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.item < items.count else {
            return tableView.dequeueReusableCell(withIdentifier: "LoadMore", for: indexPath)
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "AuditEntry", for: indexPath)
        let entry = items[indexPath.item]
        let date = Formatters.relativeDate(from: entry.date)
        let timeIntervalSinceStart = -entry.date.timeIntervalSinceNow
        let timestamp = "\(date) (\(Int(timeIntervalSinceStart)) seconds ago)"
        let kind: String
        let completionOutcome: String
        switch entry.kind {
            case .begin:
                kind = "✳️"
                completionOutcome = ""
            case .complete:
                kind = "🏁"
                completionOutcome = " Outcome: \(entry.outcome!)"
        }
        let userInitiatedSymbol = entry.userInitiated ? "👤 " : ""
        let input: String
        if let inputDescription = entry.inputDescription, inputDescription.count > 0 {
            input = " (\(inputDescription))"
        } else {
            input = ""
        }
        cell.textLabel?.text = "\(userInitiatedSymbol)\(entry.actionName)\(input)"
        cell.detailTextLabel?.text = "\(kind) \(timestamp)\(completionOutcome)"
        
        return cell
    }

    public override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard indexPath.item < items.count else {
            guard let request = TimelineDataAccessFeature.request(TimelineDataAccessFeature.loadMoreResults) else {
                preconditionFailure("This UI requires that TimelineFeature is enabled. Set TimelineFeature.isAvailable = true at startup.")
            }
            request.perform(using: self, with: 20)
            return nil
        }
        let entry = items[indexPath.item]
        selectedEntry = (indexPath.item, entry)
        return indexPath
    }

    // MARK: Segues
    
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowHistoryDetail", let selected = selectedEntry {
            let destination = segue.destination as! TimelineEntryViewController
            destination.actionHistoryEntry = selected.1
            destination.dataSource = self
        }
    }

    // MARK: Outlets and actions
    
    @objc public func shareAudit() {
        let url = DebugReporting.gatherReportZip()
        let shareViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        shareViewController.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: url)
        }
        present(shareViewController, animated: true)
    }

    @objc public func dismissAudit() {
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: TimeOrderedResultsControllerDelegate

extension TimelineViewController {
    public func newResultsInserted(items: [Any]) {
        let entries = items as! [TimelineEntry]
        let indexes = (0..<entries.count).indices.map { IndexPath(row: $0, section: 0) }
        
        // Update the model
        self.items.insert(contentsOf: entries, at: 0)
        
        tableView.insertRows(at: indexes, with: firstDataReceived ? .automatic : .none)
        firstDataReceived = true
    }
    
    public func oldResultsLoaded(items: [Any]) {
        let entries = items as! [TimelineEntry]
        let indexes = (0..<entries.count).indices.map { IndexPath(row: self.items.count + $0, section: 0) }
        
        // Update the model
        self.items.append(contentsOf: entries)
        
        tableView.insertRows(at: indexes, with: firstDataReceived ? .automatic : .none)
        firstDataReceived = true
    }
}

extension TimelineViewController: TimelineEntryViewControllerDataSource {
    func selectEntry(at index: Int) {
        selectedEntry = (index, items[index])
        tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .middle)
    }
    
    func actionHistoryPreviousEntry() -> TimelineEntry? {
        guard let selected = selectedEntry, selected.0 < items.count-1 else {
            return nil
        }
        selectEntry(at: selected.0 + 1)
        return selectedEntry?.1
    }

    func actionHistoryNextEntry() -> TimelineEntry? {
        guard let selected = selectedEntry, selected.0 > 0 else {
            return nil
        }
        selectEntry(at: selected.0 - 1)
        return selectedEntry?.1
    }
}
