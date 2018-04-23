# Activities

Apple platforms is `NSUserActivity` for a variety of purposes to tell the operating system about something the user is doing. It is used across the platforms to make the user experience more efficient. This includes support for Handoff, Siri Suggestions (AKA Siri Proactive), Spotlight Search, and even ClassKit for education apps.

Flint’s Activities feature can automatically register `NSUserActivity` for you when users perform actions in your app. You can determine which actions qualify for this (“Save” is not something that makes sense for a Handoff action), and control the attributes passed to the operating system.

## Enabling Activities on an Action

TBD

## Adding code so your app handles incoming activities

TBD

## Setting custom attributes on an Action

TBD

## Things Flint cannot do for you

You need to update Info.plist `NSUserActivityTypes`. Flint generates automatic activity types using the pattern XXXXXXXXXXXX, but you can also explicitly set the ID yourself. Either way all the types have to be listed in your app’s `Info.plist`

## Troubleshooting and testing

* Activities that also register the item for Spotlight search *must* have a title. Flint will alert you to this if you forget.
* If Handoff or other activity
