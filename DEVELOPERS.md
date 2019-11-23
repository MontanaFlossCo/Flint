# Flint Development

Information for people making pull requests or releases.

## Release process

This is mainly so I don't forget what to do each time.

### Pre-release 

1. Create a branch of FlintDemo-iOS matching the new Flint release number
2. Verify that FlintDemo branch builds and runs correctly, pushing any required changes
3. Write / update the docs in Flint-Documentation and push these to `master` (for now, it's the simplest solution)

### Doing the release

1. Write some meaningful release notes
2. Create the Release in Github, using the brief release notes with links to every issue mentioned
3. Do the release on Cocoapods:

```
pod trunk push Flint.podspec
pod trunk push FlintUI.podspec
```
4. Check out and build FlintDemo from the matching version branch and use Carthage to pull the dependency from the version tag, rather than your release branch

### Things only the project lead can do currently

1. Create a log post for flint.tools, including the release notes
2. Update the change log on flint.tools with a summary of the release notes
3. Run the script to rebuild the jekyll site flint tools and the jazzy docs
4. Push to the website's `master` and we're done

