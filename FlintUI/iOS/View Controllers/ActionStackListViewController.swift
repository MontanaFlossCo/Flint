//
//  ActionStackListViewController.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 25/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import FlintCore

public class ActionStackListViewController: UITableViewController {
    var actionStacks: [ActionStack] = []
    
    public static func instantiate() -> ActionStackListViewController {
        let storyboard = UIStoryboard(name: "FlintUI", bundle: Bundle(for: ActionStackListViewController.self))
        let viewController = storyboard.instantiateViewController(withIdentifier: "ActionStackList") as! ActionStackListViewController
        return viewController
    }
    
    var selectedStack: ActionStack?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Action Stacks"
        if navigationController?.viewControllers.first == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissActionStacks))
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareAudit))

        actionStacks = ActionStackTracker.instance.allActionStacks()
    }
    
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actionStacks.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Stack", for: indexPath)
        let stack = actionStacks[indexPath.row]

        let entryCount = stack.withEntries { return $0.count }
        let userInitiatedIndicator = stack.userInitiated ? " 👤" : ""
        let date = Formatters.relativeDate(from: stack.startDate)
        
        cell.textLabel?.text = "\(stack.id):\(userInitiatedIndicator) \(stack.feature)"
        cell.detailTextLabel?.text = "[\(stack.sessionName)] \(date) (\(Int(stack.timeIntervalSinceStart)) seconds ago) — \(entryCount) entries"

        return cell
    }
    
    public override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        selectedStack = actionStacks[indexPath.row]
        return indexPath
    }

    public override func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        selectedStack = nil
        return indexPath
    }

    // MARK: Segues
    
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowStack" {
            let destination = segue.destination as! ActionStackViewController
            destination.actionStack = selectedStack
        }
    }
    // MARK: Actions
    
    @objc public func shareAudit() {
        let url = DebugReporting.gatherReportZip(options: [.machineReadableFormat])
        let shareViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        shareViewController.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: url)
        }
        present(shareViewController, animated: true)
    }

    @objc
    public func dismissActionStacks(sender: Any?) {
        dismiss(animated: true, completion: nil)
    }
}
