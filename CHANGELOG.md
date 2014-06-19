# Liquid iOS SDK Change Log

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
