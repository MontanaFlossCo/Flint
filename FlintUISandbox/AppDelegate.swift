//
//  AppDelegate.swift
//  FlintUISandbox
//
//  Created by Marc Palmer on 19/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import UIKit
import FlintCore
import FlintUI

class FakePresentationRouter: PresentationRouter {
    func presentation<FeatureType, ActionType>(for actionBinding: StaticActionBinding<FeatureType, ActionType>,
                                               input: ActionType.InputType) -> PresentationResult<ActionType.PresenterType> {
        return .appPerformed
    }
    
    func presentation<FeatureType, ActionType>(for conditionalActionBinding: ConditionalActionBinding<FeatureType, ActionType>,
                                               input: ActionType.InputType) -> PresentationResult<ActionType.PresenterType> {
        return .appPerformed
    }
} 

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var testTimer: DispatchSourceTimer?
    var controller: AuthorisationController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Flint.quickSetup(FakeFeatures.self, domains: [], initialDebugLogLevel: .debug, initialProductionLogLevel: .info)
        Flint.register(group: FlintUIFeatures.self)
        
        // Spit out a fake action every few seconds
        
        let bgLogger = FakeFeature.developmentLogger(for: "BG Timer")

        testTimer = DispatchSource.makeTimerSource(flags: [], queue: .main)
        testTimer?.schedule(deadline: DispatchTime.now(), repeating: 10.0)
        testTimer?.setEventHandler(handler: {
            bgLogger?.debug("Performing a fake action, this will show even if not in Focus")
            if let request = FakeFeature.action1.request() {
                request.perform(input: nil)
            } else {
                print("NOT Performing the fake action, permissions were not available")
            }
            bgLogger?.debug("Test output from logger")
        })
        testTimer?.resume()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            if let request = FocusFeature.request(FocusFeature.resetFocus) {
                request.perform()
            }
        }
        
        let evaluation = Flint.constraintsEvaluator.evaluate(for: FakeFeature.self)
        for result in evaluation.permissions.all {
            switch result.status {
                case .notActive: print("Inactive: \(result)")
                case .notSatisfied, .notDetermined: print("Not satisfied: \(result)")
                case .satisfied: print("Satisfied: \(result)")
            }
            print("parametersDescription: \(result.constraint.parametersDescription)")
        }
        
        controller = FakeFeature.permissionAuthorisationController(using: nil)
        controller?.begin(retryHandler: nil)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

