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
                                               with state: ActionType.InputType) -> PresentationResult<ActionType.PresenterType> {
        return .appPerformed
    }
    
    func presentation<FeatureType, ActionType>(for conditionalActionBinding: ConditionalActionBinding<FeatureType, ActionType>,
                                               with state: ActionType.InputType) -> PresentationResult<ActionType.PresenterType> {
        return .appPerformed
    }
} 

class FakeFeatures: FeatureGroup {
    static var name = "MyFakeFeaturesAliased"
    static var subfeatures: [FeatureDefinition.Type] = [FakeFeature.self]
}

final class FakeFeature: ConditionalFeature {
    static var name = "FakeFeature1"
    
    static var description = "A fake feature"
    
    static let action1 = action(DoSomethingFakeAction.self)
    
    static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(action1)
    }

    static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.iOSOnly = 10
        requirements.permission(.camera)
        requirements.permission(.photos)
    }
}

final class DoSomethingFakeAction: Action {
    typealias InputType = NoInput
    typealias PresenterType = NoPresenter
    
    static var activityTypes: Set<ActivityEligibility> = [.handoff]
    
    static func perform(with context: ActionContext<InputType>, using presenter: PresenterType, completion: @escaping (ActionPerformOutcome) -> Void) {
        context.logs.development?.info("Testing logs from fake feature")
        completion(.success(closeActionStack: true))
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var testTimer: DispatchSourceTimer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Flint.quickSetup(FakeFeatures.self, domains: [], initialDebugLogLevel: .info, initialProductionLogLevel: .info)
        Flint.register(FlintUIFeatures.self)
        
        // Spit out a fake action every few seconds
        
        let logger = Logging.development?.contextualLogger(with: "Testing", topicPath: TopicPath(feature: FakeFeatures.self))

        testTimer = DispatchSource.makeTimerSource(flags: [], queue: .main)
        testTimer?.schedule(deadline: DispatchTime.now(), repeating: 10.0)
        testTimer?.setEventHandler(handler: {
            print("Performing a fake feature, this will show even if not in Focus")
            if let request = FakeFeature.action1.request() {
                request.perform()
            }
            logger?.debug("Test output from logger")
        })
        testTimer?.resume()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            if let request = FocusFeature.request(FocusFeature.resetFocus) {
                request.perform(with: .none)
            }
        }
        
        let evaluation = Flint.constraintsEvaluator.evaluate(for: FakeFeature.self)
        for result in evaluation.permissions.all {
            if !result.isActive {
                print("Inactive: \(result)")
            }
            if result.isFulfilled != true {
                print("Not fulfilled: \(result)")
            }
            print("parametersDescription: \(result.constraint.parametersDescription)")
        }
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

