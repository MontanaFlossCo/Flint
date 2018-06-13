//
//  FlintCore.swift
//  FlintCore
//
//  Created by Marc Palmer on 07/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(CoreSpotlight)
import CoreSpotlight
#endif
#if os(iOS) || os(macOS)
import Intents
#endif
#if canImport(ClassKit)
import ClassKit
#endif

/// This is the Flint class, with entry points for application-level convenience functions and metadata.
///
/// Your application must call `Flint.quickSetup` or `Flint.setup` at startup to bootstrap the Feature & Action declarations,
/// to set up all the URL mappings and other conventions.
///
/// Failure to do so will usually result in a precondition failure in your app.
final public class Flint {

    // MARK: Dependencies
    
    /// The default link generator to use when creating automatic links to actions for Activities and so on.
    /// This is populated by default in `quickSetup` with a generator that uses the first app scheme and first domain.
    ///
    /// If you need to create URLs to actions in your app, use this. Example:
    ///
    /// ```
    /// let appUrl = Flint.linkCreator.appLink(to: MyFeature.someAction, with: someInput)
    /// let webUrl = Flint.linkCreator.universalLink(to: MyFeature.someAction, with: someInput)
    /// ```
    public static var linkCreator: LinkCreator!
    
    /// The dispatcher for all actions
    public static var dispatcher: ActionDispatcher = DefaultActionDispatcher()
    
    /// The availability checker for conditional features
    public static var availabilityChecker: AvailabilityChecker!
    
    /// The permission checker to verify availability of system permissions. You should not need to replace this
    /// unless you are writing tests and want a mock instance
    private static var _permissionChecker: SystemPermissionChecker!
    public static var permissionChecker: SystemPermissionChecker! {
        get {
            requiresSetup()
            return _permissionChecker
        }
        set {
            _permissionChecker = newValue
        }
    }

    /// The constraints evaluator used to define the constraints on features
    private static var _constraintsEvaluator: ConstraintsEvaluator!
    public static var constraintsEvaluator: ConstraintsEvaluator! {
        get {
            requiresSetup()
            return _constraintsEvaluator
        }
        set {
            _constraintsEvaluator = newValue
        }
    }
    
    /// The user feature toggles implementation. By default it will use `UserDefaults` for this, replace with your
    /// own implementation if you'd like to store these elsewhere.
    public static var userFeatureToggles: UserFeatureToggles!

    /// The purchase tracker to use to verify purchased products. Replace this with your own implementation if
    /// the Fling StoreKit tracker is not sufficient.
    public static var purchaseTracker: PurchaseTracker?

    // MARK: Metadata
    
    /// The metadata for all features available
    /// - see: `FlintUI.FeatureBrowserFeature`
    public private(set) static var allFeatures: Set<FeatureMetadata> = []
    
    /// The metadata for only the conditional features
    /// - see: `FlintUI.FeatureBrowserFeature`
    public static var conditionalFeatures: Set<FeatureMetadata> {
        return allFeatures.filter { (anyFeature) -> Bool in
            guard let _ = anyFeature.feature as? ConditionalFeatureDefinition.Type else {
                return false
            }
            return true
        }
    }
    
    /// Track all the implied parents of subfeatures
    fileprivate static var featureParents: [ObjectIdentifier:FeatureGroup.Type] = [:]

    private static var metadataAccessQueue: SmartDispatchQueue = {
        return SmartDispatchQueue(queue: DispatchQueue(label: "tools.flint.Flint.metadata"), owner: Flint.self)
    }()

    /// Get the metadata for the specified feature
    public static func metadata(for feature: FeatureDefinition.Type) -> FeatureMetadata? {
        return metadataAccessQueue.sync {
            return allFeatures.first { $0.feature == feature }
        }
    }

    // MARK: Setup and convenience functions
    
    /// Call for the default setup of loggers, link creation, automatic logging of action start/end.
    /// - param group: The main group of your application features
    /// - param domains: The list of universal link domains your app supports. The first one will be used to create new
    /// universal links. (Domains vannot be extracted automatically by Flint)
    /// - param initialDebugLogLevel: The default log level for debug logging. Default if not specified is `.debug`
    /// - param initialProductionLogLevel: The default log level for production logging. Default if not specified is `.info`
    /// - param briefLogging: Set to `true` for logging with less verbosity (primarily dates)
    public static func quickSetup(_ group: FeatureGroup.Type, domains: [String] = [], initialDebugLogLevel: LoggerLevel = .debug,
                                  initialProductionLogLevel: LoggerLevel = .info, briefLogging: Bool = true) {
        precondition(!isSetup, "Setup has already been called")

        DefaultLoggerFactory.setup(initialDebugLogLevel: initialDebugLogLevel, initialProductionLogLevel: initialProductionLogLevel, briefLogging: briefLogging)
        FlintAppInfo.associatedDomains.append(contentsOf: domains)

        let defaultScheme = FlintAppInfo.urlSchemes.first
        let defaultDomain = FlintAppInfo.associatedDomains.first
        if let scheme = defaultScheme, let domain = defaultDomain {
            linkCreator = LinkCreator(scheme: scheme, domain: domain)
        }
        
        ActionSession.quickSetupMainSession()

        commonSetup()
        register(group)
    }
    
    /// Call to set up your application features and Flint's internal features.
    ///
    /// Use this only if you have manually configured your logging and action sessions.
    public static func setup(_ group: FeatureGroup.Type) {
        precondition(!isSetup, "Setup has already been called")
        commonSetup()
        register(group)
    }
    
    /// Register the feature with Flint. Call this to register specific features if they are not already
    /// registered by way of being subfeatures of a group.
    /// Only call this if you have not passed this feature to `setup` or `quickSetup`.
    public static func register(_ feature: FeatureDefinition.Type) {
        FlintInternal.logger?.debug("Preparing feature: \(feature)")
        createMetadata(for: feature)
        
        // Evaluate the constraints before calling `prepare` - that may check its own `isAvailable` value.
        if let conditionalFeature = feature as? ConditionalFeatureDefinition.Type {
            let builder = DefaultFeatureConstraintsBuilder()
            let constraints = builder.build(conditionalFeature.constraints)
            _constraintsEvaluator.set(constraints: constraints, for: conditionalFeature)
        }

        let builder = ActionsBuilder(feature: feature)
        feature.prepare(actions: builder)

        _registerUrlMappings(feature: feature)
    }

    /// Register a feature group with Flint. This will recursively register all the subfeatures.
    /// Only call this if you have not passed this group to `setup` or `quickSetup`.
    public static func register(_ group: FeatureGroup.Type) {
        FlintInternal.logger?.debug("Preparing feature group: \(group)")
        createMetadata(for: group)
        _registerUrlMappings(feature: group)

        // Allow them all to prepare actions
        group.subfeatures.forEach { subfeature in
            let existingParent = parent(of: subfeature)
            guard existingParent == nil else {
                fatalError("Subfeature \(subfeature) of \(group) has already been registered with a parent: \(String(reflecting: existingParent))")
            }
            
            // Store the parent automatically
            metadataAccessQueue.sync {
                featureParents[ObjectIdentifier(subfeature)] = group
            }
            
            // Recurse if any of the subfeatures are groups
            if let groupType = subfeature as? FeatureGroup.Type {
                register(groupType)
            } else {
                register(subfeature)
            }
        }
        
        // Go round a second time for any that need to post-prepare, e.g. they look at other features's actions or metadata
        group.subfeatures.forEach { subfeature in
            subfeature.postPrepare()
        }

        // Apply our own sanity checks that we apply to all features and actions
        
        checkRequiredActivityTypes(features: [group])
        checkRequiredActivityTypes(features: group.subfeatures)
    }
    
    private static func checkRequiredActivityTypes(features: [FeatureDefinition.Type]) {
        let declaredActivityTypes = Set(FlintAppInfo.activityTypes)
        
        for feature in features {
            guard let featureMetadata = metadata(for: feature) else {
                preconditionFailure("We must have metadata for \(feature) by now")
            }
            for action in featureMetadata.actions {
                if action.activityTypes.count > 0 {
                    let activityID = PublishCurrentActionActivityAction.makeActivityID(forActionName: action.name)
                    if !declaredActivityTypes.contains(activityID) {
                        FlintInternal.logger?.warning("🚑 Your Info.plist NSUserActivityTypes key is missing the activity ID \(activityID) for action type \(action.typeName) which has activity types \(action.activityTypes)")
                    }
                }
            }
        }
    }

    // MARK: Integration points for App Delegates
    
    /// Open the specified URL, dispatching the appropriately mapped action if it has been set up via a
    /// `URLMapped` Feature.
    ///
    /// Add this to your AppDelegate:
    /// ```
    /// func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    ///     let result: URLRoutingResult = Flint.open(url: url, with: presentationRouter)
    ///     return result == .success
    /// }
    /// ```
    ///
    /// - param url: The URL that may point to an action in the app.
    /// - param presentationRouter: The object that will return the correct presenter for the router
    /// - return: The routing result indicating whether or not an action was found and performed
    public static func open(url: URL, with presentationRouter: PresentationRouter) -> URLRoutingResult {
        requiresSetup()
        if let request = RoutesFeature.performIncomingURL.request() {
            var performOutcome: ActionOutcome?
            ActionSession.main.perform(request, using: presentationRouter, with: url, userInitiated: true, source: .openURL) { outcome in
                FlintInternal.logger?.debug("Activity auto URL result: \(outcome)")
                performOutcome = outcome
            }
            guard let outcome = performOutcome else {
                preconditionFailure("Perform URL unexpectedly happened asynchronously")
            }
            switch outcome {
                case .success:
                    return .success
                case .failure(let error):
                    switch error {
                        case .some(PerformIncomingURLAction.URLActionError.noURLMappingFound):
                            return .noMappingFound
                        default:
                            return .failure(error: error)
                    }
            }
        } else {
            return .featureDisabled
        }
    }
    
    /// Call this to continue an `NSUserActivity` that may map to an Action in your application.
    ///
    /// Add this to your AppDelegate:
    /// ```
    /// Perform the action required to continue a user activity.
    /// ```
    /// func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
    ///     return Flint.continueActivity(activity: userActivity, with: presentationRouter) == .success
    /// }
    /// ```
    /// - param activity: The activity pass to the application
    /// - param presentationRouter: The object that will return the correct presenter for the router
    /// - return: The routing result indicating whether or not an action was found and performed
    public static func continueActivity(activity: NSUserActivity, with presentationRouter: PresentationRouter) -> URLRoutingResult {
        requiresSetup()
        if let request = ActivitiesFeature.handleActivity.request() {
            /// We know this will block on this main thread so we can "wait" for the outcome
            var performOutcome: ActionOutcome?
            
            var source: ActionSource = .continueActivity(type: .other)
            switch activity.activityType {
                case NSUserActivityTypeBrowsingWeb: source = .continueActivity(type: .browsingWeb)
#if os(iOS) || os(macOS)
                case CSQueryContinuationActionType: source = .continueActivity(type: .search)
#endif
                default:
#if os(iOS) || os(macOS)
                    // Check for a Siri intent
                    if let _ = activity.interaction {
                        source = .continueActivity(type: .siri)
                    }
#endif

#if canImport(ClassKit)
                    if #available(iOS 11.4, *) {
                        // Check for a ClassKit activity
                        if activity.isClassKitDeepLink {
                            source = .continueActivity(type: .classKit)
                        }
                    }
#endif
            }
            
            ActionSession.main.perform(request, using: presentationRouter, with: activity, userInitiated: true, source: source) { outcome in
                FlintInternal.logger?.debug("Activity auto URL result: \(outcome)")
                performOutcome = outcome
            }
            /// !!! TODO: How to get blocking completion?
            guard let outcome = performOutcome else {
                preconditionFailure("Perform URL unexpectedly happened asynchronously")
            }
            switch outcome {
                case .success:
                    return .success
                case .failure(let error):
                    switch error {
                        case .some(PerformIncomingURLAction.URLActionError.noURLMappingFound):
                            return .noMappingFound
                        default:
                            return .failure(error: error)
                    }
            }
        } else {
            return .featureDisabled
        }
    }

    // MARK: Debug functions
    
    /// Gather all logs, timelines and stacks into a single ZIP suitable for sharing.
    ///
    /// This will use `DebugReporting` to enumerate over all the `DebugReportable` objects in the app, asking each
    /// to generate their reports, and then it will zip all the contents into a single file.
    ///
    /// - return: A URL pointing to a Zip file containing the reports. You should delete this after generating it.
    public static func gatherReportZip() -> URL {
        return DebugReporting.gatherReportZip()
    }

    // MARK: Internals
    
    private static func _registerUrlMappings(feature: FeatureDefinition.Type) {
        if let urlMappedSelf = feature as? URLMapped.Type {
            FlintInternal.logger?.debug("Registering URL mappings for: \(feature)")

            let builder = URLMappingsBuilder()
            /// Force the static urlMappings to be evaluated
            urlMappedSelf.urlMappings(routes: builder)

            let mappings = builder.mappings
            metadataAccessQueue.sync {
                guard let featureMetadata = metadata(for: feature) else {
                    preconditionFailure("Cannot register URL mappings for feature \(feature) because the feature has not been prepared")
                }
                
                featureMetadata.setActionURLMappings(mappings)
            }
        }
    }
}

/// Internal helper functions
extension Flint {
    /// This will be set to true to prevent multiple calls to `setup`
    static var isSetup = false
    
    static var preconditionChangeObserver: PreconditionChangeObserver!

    /// This must always be called at startup, via one of the public setup functions,
    /// after all other features have been prepared
    static func commonSetup() {
#if !os(watchOS)
        if userFeatureToggles == nil {
            userFeatureToggles = UserDefaultsFeatureToggles()
        }
        if purchaseTracker == nil {
            purchaseTracker = StoreKitPurchaseTracker()
        }
#else
        if userFeatureToggles == nil {
            userFeatureToggles = UserDefaultsFeatureToggles()
        }
#endif
        
        if _permissionChecker == nil {
            permissionChecker = DefaultPermissionChecker()
        }
        
        constraintsEvaluator = DefaultFeatureConstraintsEvaluator(permissionChecker: _permissionChecker, purchaseTracker: purchaseTracker, userToggles: userFeatureToggles)
        
        if availabilityChecker == nil {
            availabilityChecker = DefaultAvailabilityChecker(constraintsEvaluator: _constraintsEvaluator)
        }

        preconditionChangeObserver = PreconditionChangeObserver(availabilityChecker: availabilityChecker)
        purchaseTracker?.addObserver(preconditionChangeObserver!)
        userFeatureToggles.addObserver(preconditionChangeObserver!)
        _permissionChecker?.delegate = preconditionChangeObserver
        
        register(FlintFeatures.self)
        
        isSetup = true
        
        preflightCheck()
        
        outputEnvironment()
    }

    static func outputEnvironment() {
        let devLevel = Logging.development?.level ?? .none
        let prodLevel = Logging.production?.level ?? .none
        FlintInternal.logger?.info("💥 Flint is set up. Logging: development=\(devLevel), production=\(prodLevel)")
    }
    
    /// Here we will sanity-check the setup of the Features and Actions
    static func preflightCheck() {
    }
    
    static func requiresSetup() {
        precondition(isSetup, "🚑 Flint.setup or Flint.quickSetup has not been called, you must do this at start up.")
    }
    
    static func requiresPrepared(feature: FeatureDefinition.Type) {
        metadataAccessQueue.sync {
            guard let _ = metadata(for: feature) else {
                preconditionFailure("prepare() has not been called on \(feature). Did you forget to call Flint.register or forget to add it to its parent's subfeatures list?")
            }
        }
    }
    
    static func createMetadata(for feature: FeatureDefinition.Type) {
        let featureMetadata = FeatureMetadata(feature: feature)
        metadataAccessQueue.sync {
            allFeatures.insert(featureMetadata)
        }
    }
    
    static func bind<T>(_ action: T.Type, to feature: FeatureDefinition.Type) where T: Action {
        FlintInternal.logger?.debug("Binding action \(action) to feature: \(self)")

        // Get the existing FeatureMetadata for the feature
        metadataAccessQueue.sync {
            guard let featureMetadata = metadata(for: feature) else {
                preconditionFailure("Cannot bind action \(action) to feature \(feature) because the feature has not been prepared")
            }
            
            featureMetadata.bind(action)
        }
    }

    static func publish<T>(_ action: T.Type, to feature: FeatureDefinition.Type) where T: Action {
        FlintInternal.logger?.debug("Publishing binding of action \(action) to feature: \(self)")

        metadataAccessQueue.sync {
            // Get the existing FeatureMetadata for the feature
            guard let featureMetadata = metadata(for: feature) else {
                preconditionFailure("Cannot bind action \(action) to feature \(feature) because the feature has not been prepared")
            }
            
            featureMetadata.publish(action)
        }
    }
    
    static func isDeclared<T>(_ action: T.Type, on feature: FeatureDefinition.Type) -> Bool where T: Action {
        return metadataAccessQueue.sync {
            guard let featureMetadata = metadata(for: feature) else {
                preconditionFailure("Cannot bind action \(action) to feature \(feature) because the feature has not been prepared")
            }
            
            return featureMetadata.hasDeclaredAction(action)
        }
    }
    
    static func parent(of feature: FeatureDefinition.Type) -> FeatureGroup.Type? {
        return metadataAccessQueue.sync {
            return featureParents[ObjectIdentifier(feature)]
        }
    }
}

public extension Flint {
    public static func resetForTesting() {
        metadataAccessQueue.sync {
            allFeatures = []
            featureParents = [:]
        }
        availabilityChecker = nil
        permissionChecker = nil
        constraintsEvaluator = nil
        isSetup = false
    }
}

class PreconditionChangeObserver: PurchaseTrackerObserver, UserFeatureTogglesObserver, SystemPermissionCheckerDelegate {
    let availabilityChecker: AvailabilityChecker
    
    init(availabilityChecker: AvailabilityChecker) {
        self.availabilityChecker = availabilityChecker
    }
    
    func purchaseStatusDidChange(productID: String, isPurchased: Bool) {
        // Note that thread we are notified on does not matter here, availability is threadsafe
        availabilityChecker.invalidate()
    }
    
    func userFeatureTogglesDidChange() {
        // Note that thread we are notified on does not matter here, availability is threadsafe
        availabilityChecker.invalidate()
    }
    
    func permissionStatusDidChange(_ permission: SystemPermissionConstraint) {
        // Note that thread we are notified on does not matter here, availability is threadsafe
        availabilityChecker.invalidate()
    }
}
