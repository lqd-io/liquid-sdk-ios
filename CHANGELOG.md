# Liquid iOS SDK Change Log

## 1.2.1: Fix compiler warnings
* **[fix warning]** Change deprecated `NSGregorianCalendar` to `NSCalendarIdentifierGregorian`.
* **[fix warning]** Always use `arc4random_uniform` (instead of `arc4random`) to generate random values.

## 1.2.0: New method to set multiple user attributes

* **[enhancement]** New method `setUserAttributes:` to set multiple user attributes at a time.

## 1.1.1: Small fix to "soft reset" method

* **[bugfix]** Fix `softReset:` and `hardReset:` methods (reset SDK state) that were not creating a new session.

## 1.1.0: Persistent Device ID + Session handling & Anonymous user improvements

* **[feature]** Identifying a user no longer starts a new session.
* **[feature]** Calling `resetUser:` on a nonymous user no longer creates a new Unique ID, to avoid creating more anonymous users than desired.
* **[feature]** Device Unique ID is now stored in Keychain also, to remain the same when the app is uninstalled and reinstalled again. Furthermore, if `NSUserDefaults` are reset, device ID remains the same. Detailed explanation [at this blog post](https://blog.onliquid.com/persistent-device-unique-identifier-ios-keychain/).

## 1.0.0: First iOS stable release

We're proud to announce Liquid v1.0 of the iOS SDK. We’ve been improving it with more functionalities, guaranteeing in all versions that all the data points are correctly created and tracked. We want to thank to everyone that contributed to this release, with pull requests, tracking of issues and suggestions.

## 0.9.4-beta: Fix incorrect date serialization in some regions

* **[bugfix]** Fix an issue that could cause some dates to be incorrectly serialized (to JSON) to the ISO8601 format in some system locales/regions.

## 0.9.3-beta: Stability and speed improvements

* **[enhancement]** Lots of speed and stability improvements
* **[enhancement]** Improvements on log messages
* **[bugfix]** When the app goes on background and foreground again, the request of a Liquid Package could be locking the main thread. Thanks @CristianoCastroNabia for the bug report.
* **[bugfix]** Some events were not reaching the server on rare occasions.
* **[bugfix]** When an anonymous user was aliased with an identified user, some events could still be tracked as having been done by the previous user.

## 0.9.2-beta: Improvements on iOS 6 support

* **[bugfix]** Fixes a situation that could cause a crash when an app on iOS 6 goes into background.

## 0.9.1-beta: Avoid an infinite loop when User Alias is disabled

* **[bugfix]** Fix an infinite loop when `identifyUserWithIdentifier:alias:` method is called with `alias:NO`

## 0.9.0-beta: User alias + Stability improvements + Rename device attributes

* **[feature]** Add support to **alias** *anonymous* users with *identified* users. 
* **[feature]** Anonymous users are now automatically handled. If you never identify your user, all activity will be tracked anonymously. As soon as an user is identified, all that anonymous activity will be automatically aliased to the identified user. 
* **[feature]** When a user is identified, it is kept in cache for the next launch. This means that you don't need to identify each time you start the app again.
* **[bugfix]** Fix a problem on HTTP Requests queue, that could cause duplication or loss of events.
* **[bugfix]** Fix a bug that could cause a bad access and a crash under edge cases, while loading new values for Liquid variables too often.
* **[enhancement]** Improvements on demo app.
* **[enhancement]** Better handling of background and foreground events.
* **[enhancement]** Speed and stability improvements.
* **[enhancement]** Improvements on event tracking dates that avoid two events tracked too quickly to be tracked in the wrong order.
* **[enhancements]** The use of reserved names on Users and Events attributes will raise an assert under development environment (skipped/ignored attributes in production).
* **[change]** Changed Device attributes from `camelCase` to `underscore` naming convention, and removed `_` prefix (e.g: attribute `_systemVersion` was changed to `system_version`). This will not affect your queries on Liquid dashboard.
* **[change]** Renamed `device_model` and `device_name` attributes to `model` and `name` on Device entity. This will not affect your queries on Liquid dashboard.
* **[deprecate]** Method `flushOnBackground:` was deprecated. When the app goes on background, HTTP queue is always flushed.

## 0.8.1-beta: Fixes a compilation error on Xcode

* **[enhancement]** Fixes a Xcode compilation error that occured when Liquid is integrated using the "Liquid Project" method
* **[enhancement]** Under-the-hood small refactoring on Liquid Demo App

## 0.8.0-beta: Demo App + Kiwi tests + Stability improvements

* **[feature]** Added Kiwi tests/specs for the most important Liquid components (use `Liquid.xcworkspace` in order to run them).
* **[feature]** A Demo App is now available on Liquid Project (at both `Liquid.xcodeproj` and `Liquid.xcworkspace`) to ease the integration by new developers. 
* **[feature]** A new `NSNotification` and `LiquidDelegate` is availabe to inform developers that a user was identified on Liquid SDK.
* **[feature]** Two new methods to get current entity identifiers: `deviceIdentifier:` and `sessionIdentifier:` (beyond the already existing `userIdentifier:`)
* **[enhancement]** Many stability important improvements that avoid race conditions. A lot of integration tests were created to guarantee this stability.
* **[enhancement]** In development mode, fatal Liquid configuration errors are now asserts instead of simple console logs. In production, console logs were kept.

## 0.7.2-beta: CocoaPod configuration

* **[fix]** Add Framework dependencies to CocoaPod Podspec settings and fix on `public_header_files` configuration to include all Liquid files.

## 0.7.1-beta: Small change in Xcode Project settings

* **[enhancement]** Change Xcode Project to compile Liquid as a Dynamic Library, to avoid the need to include `-all_load` linker flag.

## 0.7.0-beta: iOS 5 Support + Minor issues

* **[feature]** iOS 5 is now supported.
* **[feature]** Added a new method for SDK integration: Liquid Xcode Project.
* **[feature]** Invalid characters on attributes and invalid event names now raise a NSAssert message
* **[enhancement]** Many performance improvements on HTTP requests queue
* **[enhancement]** `CLLocation` information is now sent to Device entity, and not User entity
* **[deprecate]** `identifyUserWithIdentifier:attributes:location:` -> Use `identifyUserWithIdentifier:attributes:` instead, and `setCurrentLocation:` in separate methods.
* **[deprecate]** `setUserLocation:` -> Use `setCurrentLocation:` instead
* **[fix]** Fixes a bug that could crash the app when the app is open and closed very fast
* **[fix]** HTTP queue is now a circular queue (FIFO), privileging most recent events

## 0.6.1-beta: Stability improvements

* **[feature]** NSAsserts on Event and User attributes guarantee that only supported data types are allowed
* **[enhancement]** Some refactoring to respect modern code style guidelines
* **[enhancement]** Code optimization and stability
* **[enhancement]** Bug fixes


## 0.6.0-beta: Inline fallback values

* **[feature]** Fallback values are now defined inline, and not on a Property List file.
* **[feature]** Added support for resetting SDK. This allows developers to recover from unexpected apllication states. All default values are reset to fallback
* **[enhancement]** Logging messages improvements
* **[enhancement]** Bug fixes


## 0.5.1-beta: Device identifier (IFA/IFV/auto)

* **[enhancement]** IFA is only used if explicitly enabled. Fallback to IFV or an auto generated UID

## 0.5.0-beta: Fallback values inline + Improvements in HTTP queue

* **[feature]** Fallback values for variables can now be defined inline (in code)
* **[enhancement]** Improvements in Property List fallback values algorithm
* **[enhancement]** Improvements in loading of new values when app is paused/resumed.
* **[enhancement]** HTTP requests queue improvements
* **[enhancement]** Small enhancements in logging messages
* **[fix]** Change Liquid package name to io.lqd.ios

## 0.4.0-beta: CocoaPod and HTTPS

* **[feature]** Default API URL now uses HTTPS (SSL)
* **[feature]** Launch Liquid as a CocoaPod
* **[enhancement]** Added README.md

## 0.3.3-beta: Improvements in HTTP requests queue

* **[enhancement]** Improvements in logging messages
* **[enhancement]** Improvements in HTTP requests queue

## 0.3.2-beta: Auto-identify and multiple calendars

* **[feature]** Auto identify at first `track:` event.
* **[enhancement]** Improvements in Sessions handling
* **[fix]** Add support for Buddhist and Japanse calendars
* **[fix]** Small bug fixes
* **[fix]** Default limit of failed data point requests in queue set to 500

## 0.3.0-beta: First public release

* First public release
