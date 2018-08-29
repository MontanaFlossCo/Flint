//
//  ActionStackViewController.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 24/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import FlintCore

public class ActionStackViewController: UITableViewController {

    public static func instantiate() -> ActionStackViewController {
        let storyboard = UIStoryboard(name: "FlintUI", bundle: Bundle(for: ActionStackViewController.self))
        let viewController = storyboard.instantiateViewController(withIdentifier: "ActionStack") as! ActionStackViewController
        return viewController
    }
    
    public var actionStack: ActionStack! {
        didSet {
            update()
        }
    }
    
    enum Section: Int {
        case properties
        case entries
        
        static let last: Section = .entries
        
        static var count: Int {
            return last.rawValue+1
        }
    }
    
    enum Property: Int {
        case date
        case id
        case sessionName
        case feature
        case userInitiated
        
        static let last: Property = .userInitiated
        
        static var count: Int {
            return last.rawValue+1
        }
    }
    
    var entries: [ActionStackEntry] = []
    var selectedEntry: ActionStackEntry?
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        clearsSelectionOnViewWillAppear = false
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
            case .properties: return Property.count
            case .entries: return entries.count
        }
    }

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
            case .properties: return "Properties"
            case .entries: return "Entries"
        }
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId: String
        let title: String
        let detail: String
        switch Section(rawValue: indexPath.section)! {
            case .properties:
                cellId = "Property"
                switch Property(rawValue: indexPath.row)! {
                    case .id:
                        title = "ID"
                        detail = actionStack.id
                    case .date:
                        title = "Started (\(Int(actionStack.timeIntervalSinceStart)) seconds ago)"
                        detail = Formatters.detailedDate(from: actionStack.startDate)
                    case .sessionName:
                        title = "Session"
                        detail = actionStack.sessionName
                    case .feature:
                        title = "Feature"
                        detail = String(reflecting: actionStack.feature)
                    case .userInitiated:
                        title = "User Initiated"
                        detail = actionStack.userInitiated ? "Yes" : "No"
                }
            case .entries:
                let entry = entries[indexPath.row]
                let date = Formatters.relativeDate(from: entry.startDate)
                detail = "\(date) (\(Int(entry.timeIntervalSinceStart)) seconds ago)"
                switch entry.details {
                    case .action(let name, _, _):
                        title = name
                        cellId = "ActionEntry"
                    case .substack(let stack):
                        title = "Sub-stack \(stack.id) for \(stack.feature)"
                        cellId = "StackEntry"
                }
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = detail

        return cell
    }

    public override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch Section(rawValue: indexPath.section)! {
            case .properties:
                selectedEntry = nil
                return nil
            case .entries:
                selectedEntry = entries[indexPath.row]
                return indexPath
        }
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedEntry = entries[indexPath.row]
        let nextViewController: UIViewController
        switch selectedEntry.details {
            case .substack(let stack):
                let detailViewController = ActionStackViewController.instantiate()
                detailViewController.actionStack = stack
                nextViewController = detailViewController
                navigationController?.pushViewController(nextViewController, animated: true)
            case .action:
                performSegue(withIdentifier: "ShowStackAction", sender: self)
        }
    }
 
    // MARK: Segues
    
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowStackAction" {
            let destination = segue.destination as! ActionStackActionViewController
            destination.actionStackEntry = selectedEntry
        }
    }
    
    // MARK: Data stuff

    func update() {
        entries = actionStack.withEntries { return $0 }
        tableView.reloadData()
        
        navigationItem.title = "Trail: \(actionStack.id)"
    }
    
    @objc func dismissActionStack() {
        dismiss(animated: true, completion: nil)
    }
}

