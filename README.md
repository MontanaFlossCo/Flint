# Flint 💥

Flint is a pure Swift framework for building iOS, tvOS, watchOS or macOS apps that utilise
[Feature Driven Development](https://www.montanafloss.co/blog/feature-driven-development), using the power of Features,
Actions and conventions to make app development and debugging more productive. 

If you don't know what Feature Driven Development can give you, please [read this linked blog post](https://www.montanafloss.co/blog/feature-driven-development) for a detailed explanation. The TL;DR description of FDD is:

> Expressing information about the Features and Actions of your application in the code itself, and using this information to make your apps better   

By defining the Features and Actions of your app using Flint, you get a bunch of functionality for free on Apple platforms. 

* **Routes** — App URL schemes and Universal links that invoke those actions for deep linking and link generation
* **Activities** — Automatic registration of NSUserActivity for actions performed, for Handoff, Siri suggestions, Spotlight search
* **Timeline** — an automatic history of the actions your users have performed  
* **Focus** — Runtime control of what is logged in your app based on your app Features. Find problems quickly without the noise of all your subsystems' logging
* **Analytics** — Automatic recording of app analytics when actions are performed, using any Analytics service you use
* **Action Stacks** — Know what your users were doing in your app for debugging and crash reporting
* **Feature Toggling** — manual feature toggling, A/B testing, IAP or subscription based toggling of features is made easy and typesafe
* Debug UIs — Flint also provides a `FlintUI` framework (iOS-only right now) with several useful debug UIs for browsing the Features and Actions declared in your application, viewing the user Timeline,  viewing Focus logs in realtime and browsing the current Action Stack.  

Much of this functionality is implemented within Flint as Flint’s own Features and Actions — it’s features all the way down.

## Documentation and sample code

If you want to see a sample project that uses Flint, there is the  [FlintDemo-iOS][] project here on Github. You can browse that to get an
idea of how a real app might use Flint.

[View the documentation](https://github.com/MontanaFlossCo/Flint-Documentation/blob/master/1.0/index.md)


## Getting started

To use Flint in your own project, use [Carthage](https://github.com/Carthage/Carthage) to add the dependency to your `Cartfile`:

```
github "MontanaFlossCo/Flint"
```

Then run `carthage bootstrap`. For faster builds you can limit to one platform and use caching, e.g.:

```
carthage bootstrap --platform iOS --cache-builds
```

## The roadmap to 1.0 final release

There is of course much left to do! Here is a high level roadmap  of planned work prior to the full 1.0 release.

* ✅ Feature and Action declaration, Action dispatch
* ✅ Timeline feature
* ✅ Deep Linking feature
* ✅ Activities feature
* ✅ Focus feature
* ✅ Action Stacks feature
* ✅ Exportable debug reports
* 👨‍💻 Early-access public API review 
* 👨‍💻 Implement IAP / Subscription validation
* 👨‍💻 Implement core unit tests, set up CI
* 👨‍💻 Implement Built-in persistent file logger
* 👨‍💻 Implement Persistence of Action Stacks, Focus Logs and Timeline at runtime
* 👨‍💻 Examples of Mixpanel, Hockey and Fabric integrations
* 👨‍💻 1.0 Release

## Philosophy

We are all-in on Swift but we don’t want to be smartypants who can’t read our own code weeks later. We take a few advanced Swift features that make great things possible: Protocol Oriented Programming, some generics and a very small amount of associated types.

We deliberately avoid the more oblique patterns because we want this framework to be very accessible and easy for everybody to reason about, irrespective of the paradigm they have chosen for their codebase.

## Community and Contributing

We have a community Slack you can join to get help and discuss ideas. Join at [flintcore.slack.com](https://join.slack.com/t/flintcore/shared_invite/enQtMzUwOTU4NTU0OTYwLWMxYTNiOTNjNmVkOTM3ZDgwNzZiNzJiNmE2NWUyMzUzMjg3ZTg4YjNmMjdhYmZkYTlmYmI2ZDQ5NjU0ZmQ3ZjU).

We would love your contributions. Please raise Issues here in Github and discuss your problems and suggestions. We look forward to your ideas and pull requests.

Flint is copyright Montana Floss Co. with an [MIT open source licence](LICENSE).

[FlintDemo-iOS]: https://github.com/MontanaFlossCo/FlintDemo-iOS
