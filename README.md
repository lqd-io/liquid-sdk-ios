![pod badge](http://img.shields.io/cocoapods/v/Liquid.svg?style=flat)

# Quick Start to Liquid SDK for iOS

This document is just a quick start introduction to Liquid SDK for iOS. You can read the full documentation at [https://www.onliquid.com/documentation/ios/](https://www.onliquid.com/documentation/ios/).

To integrate Liquid in your app, just follow the 4 simple steps below.

## Install Liquid in your project

1. Install [CocoaPods](http://cocoapods.org/) in your system
2. Open your Xcode project folder and create a file called `Podfile` with the following content:

    ```ruby
    pod 'Liquid'
    ```

3. Run `pod install` and wait for CocoaPod to install Liquid SDK. From this moment on, instead of using `.xcodeproj` file, you should start using `.xcworkspace`.

## Start using Liquid

### 1. Initialize Liquid singleton

In your **AppDelegate.m** file initialize Liquid in `application:willFinishLaunchingWithOptions:` method:

```objective-c
#import <Liquid/Liquid.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
# ifdef DEBUG
    [Liquid sharedInstanceWithToken:@"YOUR-DEVELOPMENT-APP-TOKEN" development:YES];
# else
    [Liquid sharedInstanceWithToken:@"YOUR-PRODUCTION-APP-TOKEN"];
# endif
    // The rest of your code goes here...
}
```

### 2. Identify a user (optional)

If all your users are anonymous, you can skip this step. If not, you need to identify them and define their profile.
Typically this is done at the same time your user logs in your app (or you perform an auto login), as seen in the example below:

```objective-c
[[Liquid sharedInstance] identifyUserWithIdentifier:@"UNIQUE-ID-FOR-USER"
                                         attributes:@{ @"gender": @"female",@"name":@"Anna Lynch" }];
```

The **username** or **email** are some of the typical user identifiers used by apps.

### 3. Track events

You can track any type of event in your app, using one of the following methods:

```objective-c
[[Liquid sharedInstance] track:@"clickedProfilePage"];
```
Or:

```objective-c
[[Liquid sharedInstance] track:@"boughtProduct" 
                    attributes:@{ @"productId": 123 }];
```

### 4. Personalize your app (with dynamic variables)

You can transform any old-fashioned static variable into a "Liquid" dynamic variable just by replacing it with a Liquid method. You can use a dynamic variable like this:

```objective-c
NSString *text = [[Liquid sharedInstance] stringForKey:@"welcomeText" 
                                              fallback:@"Welcome to our App"];
```

### Full documentation

We recommend you to read the full documentation at [https://www.onliquid.com/documentation/ios/](https://www.onliquid.com/documentation/ios/).


# Author

Liquid Data Intelligence, S.A.

# License

Liquid is available under the Apache license. See the LICENSE file for more info.

