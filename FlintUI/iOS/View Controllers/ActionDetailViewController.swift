//
//  ActionDetailViewController.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 20/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import UIKit
import FlintCore

class ActionDetailViewController: UITableViewController {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var typeNameLabel: UILabel!
    
    enum Section: Int {
        case properties
        case urlMappings
        
        static let last: Section = .urlMappings
        
        static var count: Int {
            return last.rawValue+1
        }
        
        var label: String {
            switch self {
                case .properties: return "Properties"
                case .urlMappings: return "URL Routes"
            }
        }
    }
    
    enum Property: Int {
        case inputType
        case presenterType
        case activityEligibility
        case analyticsID
        case intentType

        static let last: Property = .intentType
        
        static var count: Int {
            return last.rawValue+1
        }
    }
    
    var action: ActionMetadata! {
        didSet {
            update()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionLabel.text = action?.description
        typeNameLabel.text = "Action: \(action.typeName)"
        descriptionLabel.preferredMaxLayoutWidth = descriptionLabel.bounds.width
        typeNameLabel.preferredMaxLayoutWidth = typeNameLabel.bounds.width

        sizeHeaderToFit(tableView: tableView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
            case .properties: return Property.count
            case .urlMappings: return action.urlMappings.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionValue = Section(rawValue: section)!
        return sectionValue.label
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: UITableViewCell
        switch Section(rawValue: indexPath.section)! {
            case .properties:
                cell = tableView.dequeueReusableCell(withIdentifier: "Property", for: indexPath)
                let text: String
                let detail: String
                switch Property(rawValue: indexPath.item)! {
                    case .inputType:
                        text = "Input"
                        detail = inputTypeShortDescription(for: action.inputType)
                    case .presenterType:
                        text = "Presenter"
                        detail = presenterTypeShortDescription(for: action.presenterType)
                    case .analyticsID:
                        text = "Analytics ID"
                        detail = action.analyticsID ?? "<none>"
                    case .activityEligibility:
                        text = "Activities"
                        if action.activityTypes.count > 0 {
                            detail = action.activityTypes.map({ String(describing: $0) }).sorted().joined(separator: ", ")
                        } else {
                            detail = "<none>"
                        }
                    case .intentType:
                        text = "Siri Intent"
                        detail = action.intentTypeName ?? "<none>"
                }
                cell.textLabel?.text = text
                cell.detailTextLabel?.text = detail
            case .urlMappings:
                cell = tableView.dequeueReusableCell(withIdentifier: "URLMapping", for: indexPath)
                let mapping = action.urlMappings[indexPath.item]
                cell.textLabel?.text = mapping
        }

        // Configure the cell...

        return cell
    }

    public override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        self.tableView(tableView, didSelectRowAt: indexPath)
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
            case .properties:
                showDetails(forProperty: Property(rawValue: indexPath.item)!)
            default:
                break
        }
    }

    // MARK: UI Actions
    
    func showDetails(forProperty property: Property) {
        let title: String
        let detail: String
        switch property {
            case .inputType:
                title = "Input"
                detail = inputTypeLongDescription(for: action.inputType)
            case .presenterType:
                title = "Presenter"
                detail = presenterTypeLongDescription(for: action.presenterType)
            case .analyticsID:
                title = "Analytics ID"
                detail = action.analyticsID ?? "<none>"
            case .activityEligibility:
                title = "Activities"
                if action.activityTypes.count > 0 {
                    detail = action.activityTypes.map({ String(describing: $0) }).sorted().joined(separator: ", ")
                } else {
                    detail = "<none>"
                }
            case .intentType:
                title = "Siri Intent Tyoe"
                detail = action.intentTypeName ?? "<none>"
        }
        let alertController = UIAlertController(title: title, message: detail, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true)
    }
    
    // MARK: Layout
    
    func sizeHeaderToFit(tableView: UITableView) {
        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            var frame = headerView.frame
            frame.size.height = height
            headerView.frame = frame
            tableView.tableHeaderView = headerView
            headerView.setNeedsLayout()
            headerView.layoutIfNeeded()
        }
    }
    
    // MARK: Data
    
    func presenterTypeLongDescription(for presenter: Any.Type) -> String {
        if presenter == NoPresenter.self {
            return "<none>"
        } else {
            return String(reflecting: presenter)
        }
    }
    
    func presenterTypeShortDescription(for presenter: Any.Type) -> String {
        if presenter == NoPresenter.self {
            return "<none>"
        } else {
            return String(describing: presenter)
        }
    }
    
    func inputTypeLongDescription(for presenter: Any.Type) -> String {
        if presenter == NoInput.self {
            return "<none>"
        } else {
            return String(reflecting: presenter)
        }
    }
    
    func inputTypeShortDescription(for presenter: Any.Type) -> String {
        if presenter == NoInput.self {
            return "<none>"
        } else {
            return String(describing: presenter)
        }
    }
    
    func update() {
        if let action = action {
            navigationItem.title = "\(action.name)"
        }
    }
}
