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
        if let request = FakeFeature.action1.request() {
            request.perform(input: .none, completion: { (outcome: ActionOutcome) in
                switch outcome {
                    case .success:
                       assert(true)
                    case .failure(_):
                       assert(false)
                }
            })
            request.perform(input: .none, userInitiated: false, source: .application, completion: { (outcome: ActionOutcome) in
                switch outcome {
                    case .success:
                       assert(true)
                    case .failure(_):
                       assert(false)
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let navigationController = navigationController else {
            preconditionFailure()
        }
        
        switch indexPath.row {
            case 0:
                guard let request = FeatureBrowserFeature.request(FeatureBrowserFeature.show) else {
                    preconditionFailure("Feature browser is not enabled")
                }
                request.perform(presenter: navigationController)
            case 1:
                guard let request = TimelineBrowserFeature.request(TimelineBrowserFeature.show) else {
                    preconditionFailure("Timeline is not enabled")
                }
                request.perform(presenter: navigationController)
            case 2:
                guard let request = ActionStackBrowserFeature.request(ActionStackBrowserFeature.show) else {
                    preconditionFailure("Action Stack is not enabled")
                }
                request.perform(presenter: navigationController)
            case 3:
                guard let request = LogBrowserFeature.request(LogBrowserFeature.show) else {
                    preconditionFailure("Log Browser is not enabled")
                }
                request.perform(presenter: navigationController)
            default: preconditionFailure()
        }
        
    }
}

