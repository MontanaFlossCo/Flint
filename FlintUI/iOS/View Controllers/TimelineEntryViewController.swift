//
//  ActionHistoryDetailViewController.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 23/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import UIKit
import FlintCore

protocol TimelineEntryViewControllerDataSource: AnyObject {
    func actionHistoryPreviousEntry() -> TimelineEntry?
    func actionHistoryNextEntry() -> TimelineEntry?
}

class TimelineEntryViewController: UITableViewController {

    var actionHistoryEntry: TimelineEntry! {
        didSet {        
            navigationItem.title = actionHistoryEntry.actionName
        }
    }
    
    weak var dataSource: TimelineEntryViewControllerDataSource?
    
    @IBOutlet var nextBarButtonItem: UIBarButtonItem!
    @IBOutlet var previousBarButtonItem: UIBarButtonItem!
    
    // MARK: Internals
    
    enum Property: Int {
        case timestamp
        case id
        case actionType
        case featureType
        case input
        case outcome
        case session
        case userInitiated
        case source

        static let last: Property = .source
        
        static var count: Int {
            return last.rawValue + 1
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItems = [previousBarButtonItem, nextBarButtonItem]
    }
    
    // MARK: - Actions
    
    @IBAction func nextTapped(_ sender: Any) {
        if let nextItem = dataSource?.actionHistoryNextEntry() {
            actionHistoryEntry = nextItem
            tableView.reloadData()
        }
    }
    
    @IBAction func previousTapped(_ sender: Any) {
        if let previousItem = dataSource?.actionHistoryPreviousEntry() {
            actionHistoryEntry = previousItem
            tableView.reloadData()
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actionHistoryEntry == nil ? 0 : Property.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Properties"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cellID: String = "Property"
        let text: String
        let detail: String
        switch Property(rawValue: indexPath.item)! {
            case .timestamp:
                let relativeDate = Formatters.relativeDate(from: actionHistoryEntry.date)
                let kind = actionHistoryEntry.kind == .begin ? "Started" : "Completed"
                text = actionHistoryEntry.userInitiated ? "👤 \(kind) \(relativeDate)" : "\(kind) \(relativeDate)"
                detail = Formatters.detailedDate(from: actionHistoryEntry.date)
                cellID = "PropertyWithSubtitle"
            case .id:
                text = "Action Request ID"
                detail = "\(actionHistoryEntry.uniqueID)"
            case .actionType:
                text = "Action"
                detail = actionHistoryEntry.actionName
                cellID = "PropertyWithDetail"
            case .featureType:
                text = "Feature"
                detail = String(reflecting: actionHistoryEntry.feature)
                cellID = "PropertyWithDetail"
            case .input:
                text = "Input"
                detail = actionHistoryEntry.inputDescription ?? "<none>"
                cellID = "PropertyWithDetail"
            case .outcome:
                text = "Outcome"
                if let outcome = actionHistoryEntry.outcome {
                    detail = "\(outcome)"
                } else {
                    detail = "<none>"
                }
                cellID = "PropertyWithDetail"
            case .session:
                text = "Session"
                detail = actionHistoryEntry.sessionName
            case .userInitiated:
                text = "User Initiated"
                detail = actionHistoryEntry.userInitiated ? "Yes" : "No"
            case .source:
                text = "Source"
                detail = String(describing: actionHistoryEntry.source)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)

        cell.textLabel?.text = text
        cell.detailTextLabel?.text = detail

        return cell
        
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch Property(rawValue: indexPath.item)! {
            case .actionType, .featureType, .input, .outcome:
                return indexPath
            default:
                return nil
        }
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        self.tableView(tableView, didSelectRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let text: String
        let detail: String
        switch Property(rawValue: indexPath.item)! {
            case .actionType:
                text = "Action"
                detail = actionHistoryEntry.actionName
            case .featureType:
                text = "Feature"
                detail = String(reflecting: actionHistoryEntry.feature)
            case .input:
                text = "Input"
                if let info = actionHistoryEntry.inputInfo {
                    detail = String(reflecting: info)
                } else {
                    detail = "No input"
                }
            case .outcome:
                if let outcome = actionHistoryEntry.outcome {
                    text = "Outcome"
                    detail = "\(outcome)"
                } else {
                    // Nothing to show if it was not a completed entry
                    return
                }
            default:
                return
        }
        let alert = UIAlertController(title: text, message: detail, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}
