//
//  ActionStackActionViewController.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 23/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import UIKit
import FlintCore

class ActionStackActionViewController: UITableViewController {

    public static func instantiate() -> ActionStackActionViewController {
        let storyboard = UIStoryboard(name: "FlintUI", bundle: Bundle(for: ActionStackActionViewController.self))
        let viewController = storyboard.instantiateViewController(withIdentifier: "ActionStackAction") as! ActionStackActionViewController
        return viewController
    }

    var actionStackEntry: ActionStackEntry! {
        didSet {
            guard case let .action(name, source, input) = actionStackEntry.details else {
                flintBug("This view controller only displays action entries")
            }
            
            actionDetails = ActionDetails(name: name, source: source, input: input)
            navigationItem.title = name
        }
    }
    
    enum Property: Int {
        case date
        case action
        case input
        case sessionName
        case feature
        case userInitiated
        case source

        static let last: Property = .source
        
        static var count: Int {
            return last.rawValue+1
        }
    }
    
    struct ActionDetails {
        let name: String
        let source: ActionSource
        let input: String?
    }
    
    var actionDetails: ActionDetails!

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Property.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Property", for: indexPath)
        let title: String
        let detail: String
        switch Property(rawValue: indexPath.row)! {
            case .date:
                title = "Started on"
                detail = Formatters.detailedDate(from: actionStackEntry.startDate)
            case .feature:
                title = "Feature"
                detail = String(reflecting: actionStackEntry.feature)
            case .action:
                title = "Action"
                detail = actionDetails.name
            case .input:
                title = "Input"
                detail = actionDetails.input ?? "<none>"
            case .sessionName:
                title = "Session"
                detail = actionStackEntry.sessionName
            case .userInitiated:
                title = "User Initiated"
                detail = actionStackEntry.userInitiated ? "Yes" : "No"
            case .source:
                title = "Source"
                detail = String(describing: actionDetails.source)
        }
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = detail
        return cell
    }
}
