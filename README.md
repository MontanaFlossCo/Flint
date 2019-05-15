<a href="https://flint.tools"><img src="https://flint.tools/assets/img/logo-dark-on-white.svg" width="230" alt="Flint framework logo"></a>

![carthage compatible](https://img.shields.io/badge/carthage-compatible-brighttgreen.svg?style=flat)
![cocoapods compatible](https://img.shields.io/badge/cocoapods-compatible-brighttgreen.svg?style=flat)
![swift 4.1-5](https://img.shields.io/badge/swift-4.1_to_5-blue.svg?style=flat)
![xcode 9.3-10.2](https://img.shields.io/badge/Xcode-9.3_to_10.2-blue.svg?style=flat)

![Bitrise](https://img.shields.io/bitrise/5f6a9a733386ecc8/master.svg?label=Bitrise%3A%20iOS%20Xcode%2010.2&token=2aHeIvCuFPtM5FEs6fw9dg)
![Bitrise](https://img.shields.io/bitrise/b97567c7372ecf34/master.svg?label=Bitrise%3A%20macOS%20Xcode%2010.2&token=4t1YoquY5eR5aLhUU8VIxQ)
![Bitrise](https://img.shields.io/bitrise/c86c83980db3d3e2/master.svg?label=Bitrise%3A%20tvOS%20Xcode%2010.2&token=_oUyYJHNFWKvLUsUcGLyfA)
![Bitrise](https://img.shields.io/bitrise/0433151c78298a0f/master.svg?label=Bitrise%3A%20watchOS%20Xcode%2010.2&token=O2jRB64hjFBROc-qfrLRig)

![latest commit](https://img.shields.io/github/last-commit/MontanaFlossCo/Flint.svg)

Building great apps for Apple platforms involves a lot of work; **custom URL schemes**, in-app **purchases**, authorising **system permissions**, universal **links**, **Handoff** and **Siri** support, tracking **analytics** events, **feature flagging** and more. These things can be fiddly and time consuming, but you shouldn't be hand-cranking all that!
 
Flint is a framework that helps you deal with all this easily, leaving you and your team to focus on what makes your product special. Using an approach called [feature driven development](https://www.montanafloss.co/blog/feature-driven-development) you split your code into actions that make up the Features of your app and Flint takes care of the rest. These high level interactions with your UI are simple to test and decouple your UI. The icing on the cake is that because Flint knows what your users are actually doing in your app, you also get revolutionary debug capabilities for free! 🎂🎉 

We made Flint because we want people to build great apps for Apple platforms that make the most of native platform capabilities. We want to remove barriers to that, which means making it as simple as possible to get things running in a modern way.

🏠 [flint.tools](https://flint.tools) is the official web site, with guide & API docs and blog

💬 [Get help on the FlintCore Slack](https://join.slack.com/t/flintcore/shared_invite/enQtMzUwOTU4NTU0OTYwLWMxYTNiOTNjNmVkOTM3ZDgwNzZiNzJiNmE2NWUyMzUzMjg3ZTg4YjNmMjdhYmZkYTlmYmI2ZDQ5NjU0ZmQ3ZjU)

✉️ [Subscribe to the Flint newsletter](http://eepurl.com/dGW5Uj)

🐦 [Follow @flintframework on Twitter](https://twitter.com/flintframework)

📖 [View the documentation](https://flint.tools/manual) or [help us improve it with a pull request](https://github.com/MontanaFlossCo/Flint-Documentation)

🔬 [View the FlintDemo-iOS sample project](https://github.com/MontanaFlossCo/FlintDemo-iOS)

🎧 [Listen to the iDeveloper podcast interview](http://ideveloper.co/podcast187/) where project lead [Marc Palmer](https://twitter.com/marcpalmerdev) explains the motivation and ideas behind Flint



## The basics

**Features** in Flint conform to the `Feature` protocol:

```swift
import FlintCore

class DocumentManagementFeature: Feature {
    static let description = "Create, Open and Save documents"

    static let openDocument = action(DocumentOpenAction.self)

    static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(openDocument)
    }
 }
```

**Actions** are high level tasks the user can perform with your app, like "Open a document", "Close a document", "Share a document". Actions are types conforming to `Action` that are declared on features as in the above example, taking an `input` and a `presenter` that are types you define:

```swift
import FlintCore

final class DocumentOpenAction: Action {
    typealias InputType = DocumentRef
    typealias PresenterType = DocumentPresenter

    static var description = "Open a document"
    
    static func perform(context: ActionContext<DocumentRef>,
                        presenter: DocumentPresenter,
                        completion: Completion) -> Completion.Status {
        presenter.openDocument(context.input)
        return completion.completedSync(.success)
    }
}
```

Once you define actions, Flint can observe when your app performs any high level tasks. This unlocks many
behaviours like automatic `NSUserActivity` and Siri integration, analytics tracking and improved debug logging.

However, because Flint can also knowshow to **invoke your actions** for a given input, it can handle all the different app entry
points for you too, including Siri Shortcuts, app or deep-linking URLs and continued activities including Handoff, Spotlight, Siri Suggestions.
[Read more in the Features & Actions guide](https://flint.tools/manual/guides/features_and_actions).

What about features that require in-app purchases or certain system permissions? **Conditional Features** support constraints.
These can include platforms, OS versions, system permissions, in-app purchases and more. Thanks to Swift your code can’t
perform actions of conditional features unless you also handle the case where the feature is not currently available.

```swift
import FlintCore

let premiumSubscription = AutoRenewingSubscriptionProduct(name: "💎 Premium Subscription",
                                                          description: "Unlock the Selfietron!",
                                                          productID: "SUB0001")

public class SelfieFeature: ConditionalFeature {
    public static var description: String = "Selfie Posting"

    public static func constraints(requirements: FeatureConstraintsBuilder) {
      requirements.userToggled(defaultValue: true)
      
      requirements.runtimeEnabled()
      
      requirements.purchase(premiumSubscription)
      
      requirements.permissions(.camera,
                               .photos,
                               .location(usage: .whenInUse))
    }

    ...
}
```

Features that require multiple permissions or one of many purchase options are easily accommodated, and Flint will [help you build a
first class permissions onboarding](https://flint.tools/manual/guides/conditional_features) UI to maximise the number of users that
can use your feature.

When you need to perform an action from a conditional feature, you are forced to first check if the feature is available and handle
the case where it is not:

```swift
if let request = DocumentSharingFeature.share.request() {
    request.perform(withInput: document, presenter: presenter)
} else {
    showPremiumUpgradeOrPermissionAuthorisations()
}
```

This makes your code cleaner and safer. Everybody on the team can see which code is internally feature-flagged or requires a
purchase, and which permissions your app requires.

See the [programming guide for Conditional Features](https://flint.tools/manual/guides/conditional_features.md) for more details.

## Handling URLs

To handle incoming URLs all you need to do is define an action – a type that conforms to the `Action` protocol, and add it to a `Feature`
that has one or more URL routes for the action.

Consider the common case of handling a user sign-up confirmation link sent by e-mail. The URL will contain a token and the app should
open when it is tapped, verify the token and then show the "You signed in!" screen.

```swift
import FlintCore

class UserAccountManagementFeature: Feature, URLMapped {
    static let description = "User sign-up, sign in and sign out"

    static let confirmAccount = action(ConfirmAccountAction.self)
 
    static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(confirmAccount)
    }
       
    // 💥 Use `routes` to define the URLs and actions
    static func urlMappings(routes: URLMappingsBuilder) {
        routes.send("account/confirm", to: confirmAccount)
    }
}
```

Once you add the custom URL scheme to your `Info.plist` and/or an associated domain to your entitlements, your app would then
invoke the "confirm account" action when it is asked to open URLs like:

* `your-app://account/confirm`
* `https://yourappdomain.com/account/confirm`

There's support for multiple mappings per action, multiple URL schemes and multiple associated domains, so legacy URLs are no problem.
There's a little [glue code to add](https://github.com/MontanaFlossCo/Flint-Documentation/blob/master/guides/routes.md) to your app
delegate and to set up your UI when the action comes in.

The action type `ConfirmAccountAction` is not shown here, for brevity. See the [Features and Actions](https://github.com/MontanaFlossCo/Flint-Documentation/blob/master/guides/features_and_actions.md) guide for full details.

Of course you can easily perform this same action from code in your app if required:

```swift
UserAccountManagementFeature.confirmAccount.perform(withInput: confirmationToken, presenter: presenter)
```

If you need to, you can create URLs that link to these mapped actions using [`Flint.linkCreator`](https://github.com/MontanaFlossCo/Flint/blob/master/FlintCore/Core/Flint.swift). 

See the [programming guide for Routes](https://flint.tools/manual/guides/routes.md) for more details.

## Automatic Handoff and Siri Suggestions support

Apple's `NSUserActivity` is used extensively for telling the system what the user is currently doing, to integrate Handoff between devices
Siri app suggestions, some Spotlight Search integration as well as deep linking. All too often people don't implement this, because of the
challenges of executing arbitrary actions in your app when the user chooses an activity.

Flint can do this automatically for you, with zero effort if your Action also supports URL routes.

```swift
import FlintCore

final class DocumentOpenAction: Action {
    typealias InputType = DocumentRef
    typealias PresenterType = DocumentPresenter

    static var description = "Open a document"
    
    // 💥 Just tell Flint what activity types to use
    static var activityEligibility: Set<ActivityEligibility> = [.perform, .handoff]
    
    static func perform(context: ActionContext<DocumentRef>, presenter: DocumentPresenter, completion: Complettion) -> Completion.Status {
        // … do the work
    }
}
```

This is all you have to do, aside from add `NSUserActivityTypes` to your `Info.plist` and list the activity IDs automatically generated by Flint. 

You can of course customise the attributes of the `NSUserActivity` if you want to, by defining a `prepare(activity:for:)` function.
See the [Activities guide](https://github.com/MontanaFlossCo/Flint-Documentation/blob/master/guides/activities.md).

See the [programming guide for Activities](https://flint.tools/manual/guides/activities.md) for more details.

## Track analytics events when users do things

Most apps end up having to do some kind of analytics reporting to get an idea of what your users are actually doing. An analytics event is
typically an event ID and a dictionary of keys and values. Flint makes emitting these easy and consistent, using any analytics service you want.
Even your own home-spun backend. 

So when your marketing people say they want their analytics reporting system to show them when people open documents, you simply set
the `analyticsID` property on the action, and Flint's `AnalyticsReporting` component will automatically pick it up whenever that action is
performed, passing it to your analytics provider.

```swift
import FlintCore

final class DocumentOpenAction: Action {
    typealias InputType = DocumentRef
    typealias PresenterType = DocumentPresenter

    static let description = "Open a document"
    
    // 💥 Enable analytics with just one property.
    static let analyticsID = "user-open-document"
    
    static func perform(context: ActionContext<DocumentRef>, presenter: DocumentPresenter, completion: Completion) -> Completion.Status {
        // … do the work
    }
}
```

Of course you can customise the dictionary of data passed to the Analytics provider by defining an `analyticsAttributes()` function.

See the [programming guide for Analytics](https://flint.tools/manual/guides/analytics.md) for more details.

## Getting started

Flint supports Carthage and Cocoapods. See the [Getting Started guide](https://flint.tools/manual/guides/getting_started)

## Find out more

All this is just the tip of the iceberg. Flint has much more to offer and through the use of protocols almost everywhere, has many extension
and customisation points so that you aren't locked in to anything like a specific analytics provider.

If you want to see a sample project that uses Flint, there is the  [FlintDemo-iOS][] project here on Github. You can browse that to get an
idea of how a real app might use Flint.

[View all the documentation](https://flint.tools/manual/)

## The roadmap to 1.0 final release

There is of course much left to do! Here is a high level roadmap  of planned work prior to the full 1.0 release.

* ✅ Feature and Action declaration, Action dispatch
* ✅ Timeline feature
* ✅ Deep Linking feature
* ✅ Activities feature
* ✅ Focus feature
* ✅ Action Stacks feature
* ✅ Exportable debug reports
* ✅ Set up CI
* ✅ Early-access public API review 
* ✅ Siri Intents support
* ✅ Implement Built-in persistent file logger
* ✅ Implement Persistence of Action Stacks, Focus Logs and Timeline at runtime
* ✅ Implement IAP / Subscription validation
* ✅ Implement core unit tests
* 👨‍💻 1.0 Release

## Philosophy

We are all-in on Swift but we don’t want to be smartypants who can’t read our own code weeks later. We take a few advanced Swift 
eatures that make great things possible: Protocol Oriented Programming, some generics and a very small amount of associated types.

We deliberately avoid the more oblique patterns because we want this framework to be very accessible and easy for everybody to reason
about, irrespective of the paradigm they have chosen for their codebase.

## Community and Contributing

We have a community Slack you can join to get help and discuss ideas. Join at [flintcore.slack.com](https://join.slack.com/t/flintcore/shared_invite/enQtMzUwOTU4NTU0OTYwLWMxYTNiOTNjNmVkOTM3ZDgwNzZiNzJiNmE2NWUyMzUzMjg3ZTg4YjNmMjdhYmZkYTlmYmI2ZDQ5NjU0ZmQ3ZjU).

We would love your contributions. Please raise Issues here in Github and discuss your problems and suggestions. We look forward to your ideas and pull requests.

Flint is copyright Montana Floss Co. with an [MIT open source licence](LICENSE).

[FlintDemo-iOS]: https://github.com/MontanaFlossCo/FlintDemo-iOS
