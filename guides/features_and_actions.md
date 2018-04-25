# Features and Actions

The definition of your app’s Features and the Actions that they provide is the fundamental starting point of Flint’s implementation of [Feature Driven Development](https://www.montanafloss.co/blog/feature-driven-development).

When starting out, if you are on iOS it can be very useful to use the `FlintUI` framework to add a debug [Feature Browser](flint_ui.md) so you can visualise what your app’s Feature graph looks like.

## Defining your first Feature Group

Your application normally has a primary feature group that has all the root-level features your app supports. You pass this to Flint when you set it up during application startup.

It is a class that you can give any name, but typically you would use something like `AppFeatures`. It just needs to conform to `FeatureGroup` and define a list of subfeatures. We'll start with that list empty:

```swift
final class AppFeatures: FeatureGroup {
    static var description = "My main app features"
    
    static var subfeatures: [FeatureDefinition.Type] = []
}```

You use this when calling `setup` or `quickSetup` at startup:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    Flint.quickSetup(AppFeatures.self)
    ...
}
```

This will get Flint examining all your features and their actions, and settig up all the other conventions including the URL routes.

You can register more than one root-level feature group, for example if you have some frameworks that also expose features, you can register these manually with `Flint.register`. You only call `setup` or `quickSetup` once.

## Defining your first Feature

Now you can define a real feature and add it to the root feature's subfeatures.

A single `Feature` in Flint lets you describe some functionality that your app offers, the actions that can be performed on that feature, and other conventions that alter app behaviour. Information about this feature is output in logs and you can use [Focus]() to limit all logging on only a subset of features.

A regular `Feature` is always available, it cannot be turned off. This means your code can always perform the actions that belong to it, without you having to think twice. Later we will cover conditional features that can be feature flagged or enabled only through purchases or user preferences.

```swift
class DocumentManagementFeature: Feature {
    static let description = "Create, Open and Save documents"

    static func prepare(actions: FeatureActionsBuilder) {
    	// We'll add actions here soon
    }
 }
```

Note that there are more things required by the `Feature` protocol, but the class will receive default inmplementations of most requirements for the `Feature` and `FeatureDefinition` protocols. 

Once you have this in place you can define an action and hook it up to the Feature using an action binding.

Note that it seems to work out nicely if you have an Xcode project Group for each Feature, with the Feature's `.swift` file in there, along side other types needed for the feature, such as the `Action`(s) and `Presenter`(s).

## Defining your first Action

We've now got a feature so let's add an `Action`. An `Action` in Flint is a small piece of logic that represents something the application can do – usually in response to some user-driven event or external stimulus (such as a push notification or location change). Sometimes you will need actions that are not directly invoked by the user, but are required because you need to track when something happens in the app, or you need to respond to a URL.

An Action receives a single input and a presenter, which it will use to perform its work and then update the presentation. The input is any type you specify when defining the action, as is the presenter.

What we need to do here is receive a reference to a document as input, and then pass it to the presenter for display. We're not actually loading the document at this point, for simplicity.

Let's implement it.

```swift
final class DocumentOpenAction: Action {
    typealias InputType = DocumentRef
    typealias PresenterType = DocumentPresenter

    static var description = "Open a document"
    
    static func perform(with context: ActionContext<DocumentRef>, using presenter: DocumentPresenter, completion: @escaping ((ActionPerformOutcome) -> ())) {
        guard let documentRef = context.input else {
            completion(.failure(error: nil, closeActionStack: true))
            return
        }
        presenter.openDocument(documentRef)
        completion(.success(closeActionStack: false))
    }
}
```

The action's `perform` function receives a `context`, which includes the input and access to [context specific loggers](), a presenter and a completion callback. Note that your `perform` function must use your `InputType` and `PresenterType`. So the `context` argument must be an `ActionContext<...>` with the ellipsis replaced with your specific input type *or* you can go with the `InputType` alias if you so prefer. The same applies to the `presenter` argument. You will get confusing Swift compiler errors if these types do not match up, so always check that, or always explicitly use `InputType` and `PresenterType` if you want to be safe, if a little less clear.

Actions *must* call completion at some point, usually synchronously, indicating the outcome of the action. However inputs can be nil or a `NoInput`, and the presenter can be `NoPresenter`. These are special Flint types that let you indicate that you don't need either the input or presenter.

You'll notice that there is a `closeActionStack` argument set on the outcome passed to the completion handler. This flag indicates whether or not the action "closes off" a run of actions on the feature, which is used by [Action Stacks](action_stacks.md). A perfect example is closing a document, where you can have Flint discard the Action Stack. An editing feature or a drawing feature however will not typically close the Action Stack (unless implied by closing the parent Action Stack). Don't worry about the details of this too much for now. Usually you pass `false`.

Now we have to add the action to the feature, so we edit the feature declaration from earlier, adding a static propertly for the binding of action and feature, and prepare the feature by declaring that action. 

```swift
class DocumentManagementFeature: Feature, URLMapped {
    static let description = "Create, Open and Save documents"

    static let openDocument = action(DocumentOpenAction.self)

    static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(openDocument)
    }
 }
 ```

Things to note about this:

First, the static action property `createNew` shown above is how you access the action to perform it later. Second, the action values *must* be assigned the result of the `action()` function, which is a binding of the action and the feature. We use this to know which feature the action belongs to when you invoke it.

Finally, the `prepare` function must call `actions.declare` for every action you want to use. You can call `publish` on these instead, to mark them as "visible to the user" if you have UI that shows actions, such as a painting app with a tool palette.

## Calling your Action

Now comes the really easy part! In your app, you need to perform this action. Actions are perform within an `ActionSession`, which gives you a conceptual grouping for actions in your logging and debugging (e.g. one session per window, or currently open document), tracks the Action Stacks and ensures threading hygiene. By default actions are performed on the main `ActionSession.main` which expects to be called on the `main` queue. It'll crash with `fatalError` if you don't call it on that queue, to keep you safe.

Somewhere in a view controller, you can add:

```swift
DocumentManagementFeature.openDocument.perform(using: self, with: document)
```

What we are doing here is calling a convenience function called `perform` on the action binding stored in the static property `openDocument` that we defined on the feature.

The `using` argument is the presenter, so in this case the scope we're in — likely a View Controller — must conform to our own `DocumentPresenter` protocol. The `with` argument is the input, which must be a `DocumentRef` we have in scope.

This is where the magic of Swift really helps us. Those strongly typed arguments mean we can't pass the wrong thing to the action and get weird errors. It also means Xcode can autocomplete the arguments for us using only compatible types.

As mentioned, the above invocation will use the main `ActionSession`. If we have background processing in the app, we could create another `ActionSession` and dispatch to that instead, using a slightly different syntax:

```swift
// Do this at startup or "session setup" time, stash it globally somewhere
let bgProcessingSession = ActionSession(name: "bg")
                                      userInitiatedActions: true,
                                      dispatcher: Flint.dispatcher,
                                      actionStackTracker: ActionStackTracker.instance,
                                      callerQueue: myBackgroundQueue)

// Later on your background queue"
bgProcessionSession.perform(MachineLearningFeature.processImages, using: nil, with: imageStore)

```

## Conditional features

Coming soon

## Next steps

* Add [Routes](routes.md) to Actions
* Add [Activities](activities.md) support to some Actions
* Add [Analytics](analytics.md) tracking
* Use the [Timeline](timeline.md) to see what is going on in your app when things go wrong
* Start using [Focus](focus.md) to pare down your logging
