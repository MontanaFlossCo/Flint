//
//  ViewController.swift
//  FlintUISandbox
//
//  Created by Marc Palmer on 19/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import UIKit
import FlintUI
import FlintCore

class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Trigger some fake data

        FakeFeature.action1.perform(using: nil, with: .none, completion: { (outcome: ActionOutcome) in
            switch outcome {
                case .success:
                   assert(true)
                case .failure(_):
                   assert(false)
            }
        })
        FakeFeature.action1.perform(using: nil, with: .none, userInitiated: false, source: .application, completion: { (outcome: ActionOutcome) in
            switch outcome {
                case .success:
                   assert(true)
                case .failure(_):
                   assert(false)
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let navigationController = navigationController else {
            preconditionFailure()
        }
        
        switch indexPath.row {
            case 0: FeatureBrowserFeature.show.perform(using: navigationController, with: .none)
            case 1:
                guard let request = TimelineBrowserFeature.request(TimelineBrowserFeature.show) else {
                    preconditionFailure("Timeline is not enabled")
                }
                request.perform(using: navigationController, with: .none)
            case 2: ActionStackBrowserFeature.show.perform(using: navigationController, with: .none)
            case 3:
                guard let request = LogBrowserFeature.request(LogBrowserFeature.show) else {
                    preconditionFailure("Timeline is not enabled")
                }
                request.perform(using: navigationController, with: .none)
            default: preconditionFailure()
        }
        
    }
}

