# Features and Actions

The definition of your app’s Features and the Actions that they provide is the fundamental starting point of Flint’s implementation of [Feature Driven Development]().

When starting out it, if you are on iOS it can be very useful to use the `FlintUI` framework to add a debug [Feature Browser](flint_ui.md) so you can visualise what your app’s Feature graph looks like.

## Defining your first Feature

* What to call it
* Where to put it in the project
* Make sure it is `final`
* Explain the protocol extensions for defaults
* Add note for incompatible types shadowing protocol extension values
* Property defaults

## Defining your primary Feature Group

TBD

You use this when calling `setup` or `quickSetup`.

## Defining your first Action

* What is an action
* What is Input
* What is Presenter
* Info about correct signature for `perform`
* Property defaults

## Next steps

* Add [Routes](routes.md) to Actions
* Add [Activities](activities.md) support to some Actions
* Add [Analytics](analytics.md) tracking
* Use the [Timeline](timeline.md) to see what is going on in your app when things go wrong
* Start using [Focus](focus.md) to pare down your logging