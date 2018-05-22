//
//  FeatureBrowserViewController.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 22/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import UIKit
import FlintCore

public class FeatureDetailViewController: UITableViewController {

    public static func instantiate() -> FeatureDetailViewController {
        let storyboard = UIStoryboard(name: "FlintUI", bundle: Bundle(for: FeatureDetailViewController.self))
        let viewController = storyboard.instantiateViewController(withIdentifier: "FeatureBrowser") as! FeatureDetailViewController
        return viewController
    }
    
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    public var featureToDisplay: FeatureDefinition.Type! {
        didSet {
            updateFeatureData()
        }
    }
    
    enum Section: Int, CustomStringConvertible {
        case properties
        case constraints
        case features
        case actions

        static let last = actions

        var description: String {
            switch self {
                case .properties: return "Properties"
                case .constraints: return "Constraints"
                case .features: return "Features"
                case .actions: return "Actions"
            }
        }
    }
    
    enum Property: Int {
        case identifier
        case visibility
        case variation
        
        static let last = variation

        static var count: Int {
            return last.rawValue + 1
        }
    }
    
    struct SubfeatureInfo {
        let type: FeatureDefinition.Type
        let isConditional: Bool
        let isAvailable: Bool?
        let constraints: String?
        let hasSubfeatures: Bool
        let hasActions: Bool
    }
    
    struct ConstraintInfo {
        let description: String
        let status: String
    }
    
    var featureItems = [SubfeatureInfo]()
    var actionItems = [ActionMetadata]()
    var constraintInfo = [ConstraintInfo]()
    
    var selectedAction: ActionMetadata?
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        clearsSelectionOnViewWillAppear = false

        if navigationController?.viewControllers.first == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissFeatures))
        }

        headingLabel.preferredMaxLayoutWidth = headingLabel.bounds.width
        descriptionLabel.preferredMaxLayoutWidth = descriptionLabel.bounds.width

        sizeHeaderToFit(tableView: tableView)
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.last.rawValue + 1
    }

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else {
            preconditionFailure("Invalid section")
        }
        return sectionType.description
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else {
            preconditionFailure("Invalid section")
        }
        switch sectionType {
            case .properties:
                return Property.count
            case .constraints:
                return constraintInfo.count
            case .features:
                return featureItems.count > 0 ? featureItems.count : 1
            case .actions:
                return actionItems.count > 0 ? actionItems.count : 1
        }
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        // This is a bit ugly, yes it should be split out.
        switch Section(rawValue: indexPath.section)! {
            case .properties:
                cell = tableView.dequeueReusableCell(withIdentifier: "Property", for: indexPath)
                switch Property(rawValue: indexPath.row)! {
                    case .identifier:
                        cell.textLabel?.text = "ID"
                        cell.detailTextLabel?.text = featureToDisplay.identifier.description
                    case .visibility:
                        cell.textLabel?.text = "Visible"
                        cell.detailTextLabel?.text = featureToDisplay.isVisible ? "Yes" : "No"
                    case .variation:
                        let variation: String
                        if let variationID = featureToDisplay.variation {
                            variation = variationID
                        } else {
                            variation = "<none>"
                        }
                        cell.textLabel?.text = "A/B Variation"
                        cell.detailTextLabel?.text = variation
                }
            case .constraints:
                cell = tableView.dequeueReusableCell(withIdentifier: "Property", for: indexPath)
                cell.textLabel?.text = "Available"
                if let conditionalFeature = featureToDisplay as? ConditionalFeatureDefinition.Type {
                    let availableNow: String
                    switch conditionalFeature.isAvailable {
                        case .some(let value): availableNow = value ? "Yes" : "No"
                        case .none: availableNow = "<unknown>"
                    }
                    cell.detailTextLabel?.text = "\(availableNow) (\(Flint.constraintsEvaluator.description(for: conditionalFeature))"
                } else {
                    cell.detailTextLabel?.text = "Always (no constraints)"
                }
            case .features:
                guard featureItems.count > 0 else {
                    cell = tableView.dequeueReusableCell(withIdentifier: "NoSubfeatures", for: indexPath)
                    cell.textLabel?.text = "No subfeatures"
                    cell.textLabel?.textColor = UIColor.lightGray
                    return cell
                }
                cell = tableView.dequeueReusableCell(withIdentifier: "Subfeature", for: indexPath)
                let item = featureItems[indexPath.item]
                if item.isConditional {
                    let availableNow: String
                    switch item.isAvailable {
                        case .some(let value): availableNow = value ? "✅" : "⛔️"
                        case .none: availableNow = "❓"
                    }
                    cell.textLabel?.text = "\(availableNow) \(item.type.name)"
                } else {
                    cell.textLabel?.text = "✅ \(item.type.name)"
                }
                cell.accessoryType = .disclosureIndicator
                cell.detailTextLabel?.text = item.type.description
            case .actions:
                guard actionItems.count > 0 else {
                    cell = tableView.dequeueReusableCell(withIdentifier: "NoActions", for: indexPath)
                    cell.textLabel?.text = "No actions declared"
                    cell.textLabel?.textColor = UIColor.lightGray
                    return cell
                }

                cell = tableView.dequeueReusableCell(withIdentifier: "Action", for: indexPath)
                let item = actionItems[indexPath.item]
                cell.textLabel?.text = item.name
                cell.detailTextLabel?.text = item.description
        }

        return cell
    }
    
    public override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let section = Section(rawValue: indexPath.section)!
        switch section {
            case .properties:
                return nil
            case .constraints:
                return indexPath // Yes we can select constraints
            case .features: return featureItems.count > 0 ? indexPath : nil
            case .actions:
                selectedAction = actionItems[indexPath.item]
                return actionItems.count > 0 ? indexPath : nil
        }
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Note that segue handling on any prototype cells will preven this being called.
        // We handle only the self-referential case where we need another Feature browser VC
        let section = Section(rawValue: indexPath.section)!
        switch section {
            case .features:
                let selectedFeature = featureItems[indexPath.item]
                let nextViewController = FeatureDetailViewController.instantiate()
                nextViewController.featureToDisplay = selectedFeature.type
                navigationController?.pushViewController(nextViewController, animated: true)
                selectedAction = nil
            case .constraints:
                if let _ = featureToDisplay! as? ConditionalFeatureDefinition.Type {
                    let constraint = constraintInfo[indexPath.row]
                    showConstraintDetail(constraint)
                }
            default:
                return
        }
    }

    func showConstraintDetail(_ constraint: ConstraintInfo) {
        let title = "Constraint"
        let message = "\(constraint.description): \(constraint.status)"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: Segues
    
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
            case .some("ShowActionDetail"):
                let actionDetailViewController = segue.destination as! ActionDetailViewController
                actionDetailViewController.action = selectedAction
            default:
                break
        }
    }

    // MARK: Data stuff
    
    func updateFeatureData() {
        featureItems = [SubfeatureInfo]()
        
        let featuresToShow: [FeatureDefinition.Type]
        
        if let groupType = featureToDisplay as? FeatureGroup.Type {
            featuresToShow = groupType.subfeatures
        } else {
            featuresToShow = []
        }
        
        guard let metadata = Flint.metadata(for: featureToDisplay) else {
            preconditionFailure("Feature not registered correctly with Flint")
        }
        
        actionItems = metadata.actions
        let subfeatureItems = featuresToShow.map(subfeatureInfo)
        featureItems.append(contentsOf: subfeatureItems)

        constraintInfo.removeAll()
        if let conditionalFeature = featureToDisplay as? ConditionalFeatureDefinition.Type {
            let evaluationResult = Flint.constraintsEvaluator.evaluate(for: conditionalFeature)

            func _addConstraintInfo(platform: Platform, constraint: PlatformConstraint, status: String) {
                let info = ConstraintInfo(description: "Platform: \(platform) \(constraint)", status: status)
                constraintInfo.append(info)
            }

            for (platform, constraint) in evaluationResult.satisfied.allDeclaredPlatforms {
                _addConstraintInfo(platform: platform, constraint: constraint, status: "✅")
            }
            for (platform, constraint) in evaluationResult.unsatisfied.allDeclaredPlatforms {
                _addConstraintInfo(platform: platform, constraint: constraint, status: "🚫")
            }
            for (platform, constraint) in evaluationResult.unknown.allDeclaredPlatforms {
                _addConstraintInfo(platform: platform, constraint: constraint, status: "❓")
            }
        }
        
        tableView.reloadData()

        navigationItem.title = featureToDisplay.name

        let feature: FeatureDefinition.Type = featureToDisplay
        if  feature is FeatureGroup.Type {
            headingLabel.text = "Group: \(String(reflecting: feature))"
        } else {
            headingLabel.text = "Feature: \(String(reflecting: feature))"
        }
        descriptionLabel.isHidden = false
        let description: String
        if !(FocusFeature.dependencies.focusSelection?.shouldSuppress(feature: feature) == true) {
            description = featureToDisplay.description
        } else {
            description = "\(featureToDisplay.description)\n\n📷 Currently in focus"
        }
        descriptionLabel.text = description
        
        sizeHeaderToFit(tableView: tableView)
    }
    
    func subfeatureInfo(for featureType: FeatureDefinition.Type) -> SubfeatureInfo {
        var hasActions = false

        guard let metadata = Flint.metadata(for: featureType) else {
            preconditionFailure("Flint features have not been initialised correctly, no metadata for \(featureType)")
        }
        hasActions = metadata.actions.count > 0

        var hasSubfeatures = false
        if let groupType = featureType as? FeatureGroup.Type {
            hasSubfeatures = groupType.subfeatures.count > 0
        }
        let isConditional = featureType is ConditionalFeatureDefinition.Type
        let isAvailable = (featureType as? ConditionalFeatureDefinition.Type)?.isAvailable
        let constraints = isConditional ? Flint.constraintsEvaluator.description(for: featureType as! ConditionalFeatureDefinition.Type) : nil
        return SubfeatureInfo(type: featureType,
                              isConditional: isConditional,
                              isAvailable: isAvailable,
                              constraints: constraints,
                              hasSubfeatures: hasSubfeatures,
                              hasActions: hasActions)
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
    
    // MARK: Actions
    
    @objc func dismissFeatures() {
        dismiss(animated: true, completion: nil)
    }
}

