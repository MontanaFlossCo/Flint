//
//  RootFeaturesViewController.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 22/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import UIKit
import FlintCore

public class FeatureBrowserViewController: UITableViewController {

    public static func instantiate() -> FeatureBrowserViewController {
        let storyboard = UIStoryboard(name: "FlintUI", bundle: Bundle(for: FeatureBrowserViewController.self))
        let viewController = storyboard.instantiateViewController(withIdentifier: "RootFeatures") as! FeatureBrowserViewController
        return viewController
    }
    
    var rootFeatures: [FeatureDefinition.Type] = []
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        prepareData()
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Data
    
    func prepareData() {
        rootFeatures = Flint.allFeatures.flatMap {
            if let _ = $0.feature as? FeatureGroup.Type,
                    $0.feature.parent == nil {
                return $0.feature
            } else {
                return nil
            }
        }
    }

    // MARK: - Table view data source

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rootFeatures.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Group", for: indexPath)
        
        let feature = rootFeatures[indexPath.row]
        if let conditionalFeature = feature as? ConditionalFeatureDefinition.Type {
            let availableNow: String
            switch conditionalFeature.isAvailable {
                case .some(let value): availableNow = value ? "✅" : "⛔️"
                case .none: availableNow = "❓"
            }
            cell.textLabel?.text = "\(availableNow) \(feature.name)"
        } else {
            cell.textLabel?.text = "✅ \(feature.name)"
        }
        cell.detailTextLabel?.text = feature.description

        return cell
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let feature = rootFeatures[indexPath.row]
        let detailViewController = FeatureDetailViewController.instantiate()
        detailViewController.featureToDisplay = feature
        navigationController?.pushViewController(detailViewController, animated: true)
    }

}
