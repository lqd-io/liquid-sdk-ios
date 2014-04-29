# Quick Start to Liquid SDK for iOS

This document is just a quick start introduction to Liquid SDK for iOS. You can read the full documentation at [http://lqd.io/documentation/](http://lqd.io/documentation/).

To integrate Liquid in your app, just follow 4 simple steps below.

## Install Liquid in your project

1. Install [CocoaPods](http://cocoapods.org/) in your system
2. Open your Xcode project folder and create a file called `Podfile` with the following content:

    ```
    pod 'Liquid', git: https://github.com/lqd-io/liquid-sdk-ios.git
    ```

3. Run `pod install` and wait for CocoaPod to install Liquid SDK. From this moment on, instead of using `.xcodeproj` file, you should start using `.xcworkspace`.

## Start using Liquid

### 1. Initialize Liquid singleton

In your **AppDelegate.m** file initialize Liquid in `application:willFinishLaunchingWithOptions:` method:

    #import <Liquid/Liquid.h>

    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    # ifdef DEBUG
        [Liquid sharedInstanceWithToken:@"YOUR-DEVELOPMENT-APP-TOKEN" development:YES" development:YES];
    # else
        [Liquid sharedInstanceWithToken:@"YOUR-PRODUCTION-APP-TOKEN"];
    # endif
        // The rest of your code goes here...
    }

### 2. Identify a user (optional)

If all your users are anonymous, you can skip this step. If not, you need to identify them and define their profile.
Typically this is done at the same time your user logs in your app (or you perform an auto login), as seen in the example below:


    [[Liquid sharedInstance] identifyUserWithIdentifier:@"UNIQUE-ID-FOR-USER"
                                         withAttributes:@{@"gender": @"female"},
                                                             "name": @"Anna Lynch"];

The **username** or **email** are some of the typical user identifiers used by apps.

### 3. Track events

You can track any type of event in your app, using one of the following methods:

    [[Liquid sharedInstance] track:@"clickedProfilePage"]
    [[Liquid sharedInstance] track:@"boughtProduct"
                    withAttributes:@{ @"productId": 123 }]

We recommend you to name your events and attributes using camelCaseConventionNaming.

### 4. Personalize your app (with dynamic variables)

You can transform any old-fashioned static variable into a "liquid" dynamic variable just by replacing it with a Liquid method. You can use a dynamic variable like this:

    NSString *text = [[Liquid sharedInstance] stringValueForVariable:@"welcomeText"];

You need to define your default values in the Property List file `LiquidVariables.plist`. These values will be assumed in the first launch of your app (event if no Internet connection is available).

For the example above, this Property List file could include a single entry with the value `"Welcome to Liquid"` for key `welcomeText`.


### Full documentation

We recommend you to read the full documentation at [http://lqd.io/documentation/](http://lqd.io/documentation/).


# Author

Liquid Data Intelligence, S.A.

# License

Liquid is available under the LGPL license. See the LICENSE file for more info.

