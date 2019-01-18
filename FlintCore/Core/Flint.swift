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
#if canImport(ClassKit)
import ClassKit
#endif
#if canImport(Intents)
import Intents
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
        return SmartDispatchQueue(queue: DispatchQueue(label: "tools.flint.Flint.metadata"))
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
                                  initialProductionLogLevel: LoggerLevel = .none, briefLogging: Bool = true) {
        flintUsagePrecondition(!isSetup, "Setup has already been called")

        DefaultLoggerFactory.setup(initialDebugLogLevel: initialDebugLogLevel, initialProductionLogLevel: initialProductionLogLevel, briefLogging: briefLogging)
        FlintAppInfo.associatedDomains.append(contentsOf: domains)

        let defaultScheme = FlintAppInfo.urlSchemes.first
        let defaultDomain = FlintAppInfo.associatedDomains.first
        
        // Don't create a link creator unless we can do _something_ with it, so that advisories can come out if
        // the dev actually tries to create links without setting up the app properly
        if defaultScheme != nil || defaultDomain != nil {
            linkCreator = LinkCreator(scheme: defaultScheme, domain: defaultDomain)
        }
        
        // Unless we're debugging Flint we don't want this stuff.
        Logging.development?.setLevel(for: FlintInternal.coreLoggingTopic, to: .none)
        Logging.production?.setLevel(for: FlintInternal.coreLoggingTopic, to: .none)

        ActionSession.quickSetupMainSession()

        commonSetup()
        register(group: group)
    }
    
    /// Call to set up your application features and Flint's internal features.
    ///
    /// Use this only if you have manually configured your logging and action sessions.
    public static func setup(_ group: FeatureGroup.Type) {
        flintUsagePrecondition(!isSetup, "Setup has already been called")
        commonSetup()
        register(group: group)
    }
    
    /// Register the feature with Flint. Call this to register specific features if they are not already
    /// registered by way of being subfeatures of a group.
    /// Only call this if you have not passed this feature to `setup` or `quickSetup`.
    ///
    /// Registration of features at runtime is required because Swift does not provide runtime discovery of types
    /// conforming to a protocol, without using the Objective-C runtime upon which we do not want to depend, to be future
    /// proof. We need to know which types are features because:
    ///
    /// * We want to be able to show the info about all the features in debug UIs
    /// * Some apps will want to be able to show info about features in their user-facing UIs
    /// * We need to process the conventions on the types to know what actions they support
    /// * We need to process the conventions on the types to know what URL mappings they support, if any
    /// * We need to know if a feature is enabled currently, and to test for permissions and preconditions
    ///
    /// We can switch to lazy registration (processing of conventions etc.) at a later point to reduce
    /// startup overheads. However we will still need to know the types required to e.g. invoke an action on a feature via a URL,
    /// or continue an activity, or perform a Siri shortcut.
    ///
    /// If users only register some of their feature types, they would have to always remember to register all feature types
    /// that require URL mappings and/or have actions that support activity continuation. This is very error prone,
    /// and should be discouraged. It is better to minimize the overheads at the point of calling `register` and defer
    /// any processing where possible. Even in this case it is unlikely to be very profitable because you need to evaluate
    /// the conventions in order to know whether or not an Action or Feature is going to be required for URL or activity handling.
    ///
    /// - note: Even with the Objective-C runtime, iterating (and hence forcing `+load`) on all Obj-C compatible classes
    /// is a slow process as there are thousands of them.
    public static func register(_ feature: FeatureDefinition.Type) {
        flintUsagePrecondition(!(feature is FeatureGroup.Type), "You must call register(group:) with feature groups")
        FlintInternal.logger?.debug("Preparing feature: \(feature)")
        _register(feature)
    }

    private static func _register(_ feature: FeatureDefinition.Type) {
        createMetadata(for: feature)
        
        // Evaluate the constraints before calling `prepare` - that may check its own `isAvailable` value.
        if let conditionalFeature = feature as? ConditionalFeatureDefinition.Type {
            let builder = DefaultFeatureConstraintsBuilder()
            let constraints = builder.build(conditionalFeature.constraints)
            _constraintsEvaluator.set(constraints: constraints, for: conditionalFeature)
        }

        let builder = ActionsBuilder(feature: feature, activityMappings: ActionActivityMappings.instance)
        
        // Allow the feature to prepare its action declarations
        feature.prepare(actions: builder)

        _registerUrlMappings(feature: feature)
        _registerIntentMappings(feature: feature)
    }
    
    /// Register a feature group with Flint. This will recursively register all the subfeatures.
    /// Only call this if you have not passed this group to `setup` or `quickSetup`.
    ///
    /// Registration of features at runtime is required because Swift does not provide runtime discovery of types
    /// conforming to a protocol, without using the Objective-C runtime upon which we do not want to depend, to be future
    /// proof. We need to know which types are features because:
    ///
    /// * We want to be able to show the info about all the features in debug UIs
    /// * Some apps will want to be able to show info about features in their user-facing UIs
    /// * We need to process the conventions on the types to know what actions they support
    /// * We need to process the conventions on the types to know what URL mappings they support, if any
    /// * We need to know if a feature is enabled currently, and to test for permissions and preconditions
    ///
    /// We can switch to lazy registration (processing of conventions etc.) at a later point to reduce
    /// startup overheads. However we will still need to know the types required to e.g. invoke an action on a feature via a URL,
    /// or continue an activity, or perform a Siri shortcut.
    ///
    /// If users only register some of their feature types, they would have to always remember to register all feature types
    /// that require URL mappings and/or have actions that support activity continuation. This is very error prone,
    /// and should be discouraged. It is better to minimize the overheads at the point of calling `register` and defer
    /// any processing where possible. Even in this case it is unlikely to be very profitable because you need to evaluate
    /// the conventions in order to know whether or not an Action or Feature is going to be required for URL or activity handling.
    ///
    /// - note: Even with the Objective-C runtime, iterating (and hence forcing `+load`) on all Obj-C compatible classes
    /// is a slow process as there are thousands of them.
    public static func register(group: FeatureGroup.Type) {
        FlintInternal.logger?.debug("Preparing feature group: \(group)")
        _register(group)

        // Allow them all to prepare actions
        group.subfeatures.forEach { subfeature in
            let existingParent = parent(of: subfeature)

            flintUsagePrecondition(existingParent == nil, "Subfeature \(subfeature) of \(group) has already been registered with a parent: \(String(reflecting: existingParent))")
            
            // Store the parent automatically
            metadataAccessQueue.sync {
                featureParents[ObjectIdentifier(subfeature)] = group
            }
            
            // Recurse if any of the subfeatures are groups
            if let groupType = subfeature as? FeatureGroup.Type {
                register(group: groupType)
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
        
        /// !!! TODO: Change this to use metadata stored in ActionActivityMappings.instance
        for feature in features {
            guard let featureMetadata = metadata(for: feature) else {
                flintBug("We must have metadata for \(feature) by now")
            }
            for action in featureMetadata.actions {
                if action.activityTypes.count > 0 {
                    let activityID = ActionActivityMappings.makeActivityID(forActionNamed: action.name, of: feature)
                    if !declaredActivityTypes.contains(activityID) {
                        flintAdvisoryNotice("Your Info.plist NSUserActivityTypes key is missing the activity ID \(activityID) for action type \(action.typeName) which has activity types \(action.activityTypes)")
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
    public static func open(url: URL, with presentationRouter: PresentationRouter) -> MappedActionResult {
        requiresSetup()
        if let request = RoutesFeature.performIncomingURL.request() {
            var performOutcome: ActionOutcome?
            request.perform(input: url, presenter: presentationRouter, userInitiated: true, source: .openURL) { outcome in
                FlintInternal.logger?.debug("Activity auto URL result: \(outcome)")
                performOutcome = outcome
            }
            /// !!! TODO: Replace this with CompletionStatus checks
            guard let outcome = performOutcome else {
                flintUsageError("Perform URL unexpectedly happened asynchronously")
            }
            switch outcome {
                case .success:
                    return .success
                case .failure(let error):
                    switch error {
                        case PerformIncomingURLAction.URLActionError.noURLMappingFound:
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
    public static func continueActivity(activity: NSUserActivity, with presentationRouter: PresentationRouter) -> MappedActionResult {
        requiresSetup()
        var performOutcome: ActionOutcome?

        // Work out what kind of activity it is and use the appropriate kind of action.
        
        var source: ActionSource = .continueActivity(type: .other)
        
        switch activity.activityType {
            case NSUserActivityTypeBrowsingWeb:
                source = .continueActivity(type: .browsingWeb)
#if os(iOS) || os(macOS)
            case CSQueryContinuationActionType:
                source = .continueActivity(type: .search)
#endif
            default:
#if os(iOS) || os(macOS)
                // Check for a Siri intent
#if canImport(Intents)
                if let interaction = activity.interaction {
                    source = .continueActivity(type: .siri(interaction: interaction))
                }
#endif
#endif

#if canImport(ClassKit)
                if #available(iOS 11.4, *) {
                    // This may not be linked in targets if the ClassKit framework is not linked,
                    // so we have to manually check
                    if activity.responds(to: #selector(getter: NSUserActivity.isClassKitDeepLink)) {
                        // Check for a ClassKit activity
                        if activity.isClassKitDeepLink {
                            source = .continueActivity(type: .classKit)
                        }
                    }
                }
#endif
        }

        if let request = ActivitiesFeature.handleActivity.request() {
            request.perform(input: activity, presenter: presentationRouter, userInitiated: true, source: source) { outcome in
                FlintInternal.logger?.debug("Activity auto continue result: \(outcome)")
                performOutcome = outcome
            }
        } else {
            return .featureDisabled
        }

        /// !!! TODO: This is unsafe, change to CompletionStatus and assert sync completion
        guard let outcome = performOutcome else {
            flintUsageError("Action's perform unexpectedly happened asynchronously")
        }
        switch outcome {
            case .success:
                return .success
            case .failure(let error):
                switch error {
                    case PerformIncomingURLAction.URLActionError.noURLMappingFound:
                        return .noMappingFound
                    default:
                        return .failure(error: error)
                }
        }
    }
    
    public static func performIntentAction(intent: INIntent, presenter: UntypedIntentResponsePresenter) -> MappedActionResult {
        guard let request = SiriFeature.handleIntent.request() else {
            return .featureDisabled
        }

        let intentWrapper = FlintIntentWrapper(intent: intent)
        
        var syncOutcome: ActionPerformOutcome?
        let completion = Action.Completion(queue: nil) { (outcome, wasAsync) in
            FlintInternal.logger?.debug("Intent perform outcome: \(outcome) wasAsync: \(wasAsync)");
            syncOutcome = outcome
        }
        let status: Action.Completion.Status = request.perform(input: intentWrapper, presenter: presenter, userInitiated: true, source: .intent, completion: completion)
        if status.isCompletingAsync {
            return .completingAsync
        }
        
        guard let outcome = syncOutcome else {
            flintBug("We should have a sync outcome by now");
        }
        
        let result: MappedActionResult
        
        switch outcome {
            case .success,
                 .successWithFeatureTermination:
                result = .success
            case .failure(let error),
                 .failureWithFeatureTermination(let error):
                switch error {
                    case DispatchIntentAction.IntentActionError.noMappingFound:
                        result = .noMappingFound
                    default:
                        result = .failure(error: error)
                }
        }
        
        return result
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
                    flintUsageError("Cannot register URL mappings for feature \(feature) because the feature has not been prepared")
                }
                
                featureMetadata.setActionURLMappings(mappings)
            }
        }
    }

    private static func _registerIntentMappings(feature: FeatureDefinition.Type) {
        if let intentMappedSelf = feature as? IntentMapped.Type {
            FlintInternal.logger?.debug("Registering URL mappings for: \(feature)")

            /// Force the static intentMappings to be evaluated
            let mappings = intentMappedSelf.collectIntentMappings()

            metadataAccessQueue.sync {
                guard let featureMetadata = metadata(for: feature) else {
                    flintUsageError("Cannot register Intent mappings for feature \(feature) because the feature has not been prepared")
                }
                featureMetadata.setIntentMappings(mappings)
            }
            
            IntentMappings.shared.addMappings(mappings)
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
        
        register(group: FlintFeatures.self)
        
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
        flintAdvisoryPrecondition(isSetup, "Flint.setup or Flint.quickSetup has not been called, you must do this at start up.")
    }
    
    static func requiresPrepared(feature: FeatureDefinition.Type) {
        metadataAccessQueue.sync {
            flintUsagePrecondition( nil != metadata(for: feature), "prepare() has not been called on \(feature). Did you forget to call Flint.register or forget to add it to its parent's subfeatures list?")
        }
    }
    
    static func createMetadata(for feature: FeatureDefinition.Type) {
        let featureMetadata = FeatureMetadata(feature: feature)
        metadataAccessQueue.sync {
            allFeatures.insert(featureMetadata)
        }
    }
    
    static func bind<T>(_ action: T.Type, to feature: FeatureDefinition.Type) where T: Action {
        FlintInternal.logger?.debug("Binding action \(action) to feature: \(feature)")

        // Get the existing FeatureMetadata for the feature
        metadataAccessQueue.sync {
            guard let featureMetadata = metadata(for: feature) else {
                flintBug("Cannot bind action \(action) to feature \(feature) because the feature has not been prepared")
            }
            
            featureMetadata.bind(action)
        }
    }

    static func publish<T>(_ action: T.Type, to feature: FeatureDefinition.Type) where T: Action {
        FlintInternal.logger?.debug("Publishing binding of action \(action) to feature: \(feature)")

        metadataAccessQueue.sync {
            // Get the existing FeatureMetadata for the feature
            guard let featureMetadata = metadata(for: feature) else {
                flintBug("Cannot publish action \(action) to feature \(feature) because the feature has not been prepared")
            }
            
            featureMetadata.publish(action)
        }
    }
    
    static func isDeclared<T>(_ action: T.Type, on feature: FeatureDefinition.Type) -> Bool where T: Action {
        return metadataAccessQueue.sync {
            guard let featureMetadata = metadata(for: feature) else {
                flintBug("Cannot tell if action \(action) is declared on \(feature) because the feature has not been prepared")
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
    static func resetForTesting() {
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
