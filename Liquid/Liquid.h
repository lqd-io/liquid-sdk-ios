//
//  Liquid.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIColor.h>
#import "LQDefaults.h"

@protocol LiquidDelegate <NSObject>
@optional
- (void)liquidDidReceiveValues;
- (void)liquidDidLoadValues;
- (void)liquidDidIdentifyUserWithIdentifier:(NSString *)identifier;
@end

/*!
 @class
 Liquid API.
 
 @abstract
 The primary interface for integrating Liquid into your application.
 
 @discussion
 Use the Liquid class to keep track of user, device, session and event metrics
 in the lqd.io website.
 
 <pre>
 // Initialize the Liquid API
 Liquid *liquid = [Liquid sharedInstanceWithToken:@"YOUR_API_TOKEN"];
 
 // Identify the user
 [liquid identifyUserWithIdentifier:@"username@lqd.io" attributes:[NSDictionary dictionaryWithObjects:@[@"23", @"male"] forKeys:@[@"age", @"sex"]]];
 
 // Set user attribute
 [liquid setUserAttribute:@"irish" forKey:@"nationality"];
 
 // Track an event
 [liquid track:@"purchase_click" attributes:[NSDictionary dictionaryWithObjects:@[@"33.89", @"USD"] forKeys:@[@"price", @"currency"]];
 
 // Get variables defined on Liquid
 UIColor *backgroundColor = [liquid colorForVariable:@"tableViewBackgroundColor" fallback:[UIColor black]];
 [tableView setBackgroundColor:backgroundColor];
 </pre>
 
 For more advanced usage, please see the <a href="https://lqd.io/">Liquid iOS Library Guide</a>.
 */
@interface Liquid : NSObject

extern NSString * const LQDidReceiveValues;
extern NSString * const LQDidLoadValues;
extern NSString * const LQDidIdentifyUser;

/*!
 @property
 
 @abstract
 The LiquidDelegate object that can be used to notify the application
 of variable changes.
 
 @discussion
 Using a delegate is optional. See the documentation for LiquidDelegate
 for more information.
 */

@property (atomic, retain) NSObject<LiquidDelegate> *delegate;


/*!
 @property
 
 @abstract
 The interval for the Flush timer.
 
 @discussion
 Setting a flush interval of 0 will disable the flush timer.
 */

@property (nonatomic) NSUInteger flushInterval;


/*!
 @property
 
 @abstract
 Control whether variable fallback values should be send to Liquid dashboard
 in development mode, thus assumed as default values. This is not mandatory
 for Liquid to work. It just eases and speeds up development process.
 
 @discussion
 Defaults to YES.
 */

@property (nonatomic, assign) BOOL sendFallbackValuesInDevelopmentMode;


/*!
 @property
 
 @abstract
 Max size of HTTP requests queue.
 
 @discussion
 HTTP requests are stored in a queue before being sent to server.
 If server is not reachable, queue is persisted until a connection is available.
 */

@property (nonatomic, assign) NSUInteger queueSizeLimit;


/*!
 @property
 
 @abstract
 Control whether variables should be automatically loaded when they
 are received from the server.
 
 @discussion
 This avoids the manual load of variables by calling the loadValues method.
 */

@property (atomic) BOOL autoLoadValues;


/*!
 @property
 
 @abstract
 Control the session timeout for the Liquid API.
 
 @discussion
 Lets the developer control the session timeout for the Liquid API.
 Defaults to 30 seconds.
 */

@property (nonatomic, assign) NSInteger sessionTimeout;


/*!
 @method
 
 @abstract
 Initializes and returns a singleton instance of the API.
 
 @discussion
 The purpose of the share instance is to make it easy for the common
 usage of the api, where you only send data to a single Liquid instance
 from your application. This method will set up a singleton instance 
 of the <code>Liquid</code> class. Further calls can use 
 <code>sharedInstance</code> instead.
 
 <pre>
 [[Liquid sharedIntance]track:@"Button_clicked"];
 </pre>
 
 When using this singleton accessor, <code>sharedIntanceWithToken:</code>
 must be called first, because it performs the initialization to the API.
 @param apiToken        your api token
 @param development     set to YES if you're compiling your app in a development environment
 */

+ (Liquid *)sharedInstanceWithToken:(NSString *)apiToken;
+ (Liquid *)sharedInstanceWithToken:(NSString *)apiToken development:(BOOL)development;


/*!
 @method
 
 @abstract
 Returns a previously instantiated singleton instance of the API.
 
 @discussion
 TODO
 */

+ (Liquid *)sharedInstance;


/*!
 @method
 
 @abstract
 Initializes and returns an instance of the API.
 
 @discussion
 Useful for multiple API keys.
 
 @param apiToken        your api token
 @param development     set to YES if you're compiling your app in a development environment
 */

-(instancetype)initWithToken:(NSString *)apiToken development:(BOOL)developemnt;
-(instancetype)initWithToken:(NSString *)apiToken;


/*!
 @method
 
 @abstract
 Returns the user identifier.
 
 @discussion
 Will return an identified user, either with a manual identifier
 or a automatically generated one. Must be called after an identifyUser.
 */

- (NSString *)userIdentifier;


/*!
 @method
 
 @abstract
 Returns the device identifier.
 
 @discussion
 Will return the device ID used by Liquid to identify the device.
 */

- (NSString *)deviceIdentifier;


/*!
 @method
 
 @abstract
 Returns the session identifier.
 
 @discussion
 Will return the session unique identifier - generated by Liquid.
 */

- (NSString *)sessionIdentifier;


/*!
 @method
 
 @abstract
 Identifies the user on to the Liquid API with a given identifier.
 
 @discussion
 This will identify the user with the given identifier string.
 
 @param identifier        unique name identifying the user
 */

-(void)identifyUserWithIdentifier:(NSString *)identifier;


/*!
 @method
 
 @abstract
 Identifies the user on to the Liquid API with a given identifier.
 
 @discussion
 This will identify the user with the given identifier string.
 
 @param identifier        unique name identifying the user
 @param alias             after identifying user, alias/link the previous anonymous user with it
 */

-(void)identifyUserWithIdentifier:(NSString *)identifier alias:(BOOL)alias;


/*!
 @method
 
 @abstract
 Resets user data to its initial state (a new Unique ID is generated).
 
 @discussion
 This will reset all cached user data (unique identifier and attributes).
 From this moment on, current user will become non identified (a.k.a. anonymous)
 one (initial state of the SDK). Also, current session is ended and a
 new one is started.
 */

- (void)resetUser;


/*!
 @method
 
 @abstract
 Identifies the user on to the Liquid API with a given identifier and some
 attributes.
 
 @discussion
 This will identify the user with the given identifier string and a 
 dictionary of attributes to better classify the user.
 
 @param identifier        unique name identifying the user
 @param attributes        dictionary of user attributes
 */

-(void)identifyUserWithIdentifier:(NSString *)identifier attributes:(NSDictionary *)attributes;


/*!
 @method
 
 @abstract
 Identifies the user on to the Liquid API with a given identifier and some
 attributes.
 
 @discussion
 This will identify the user with the given identifier string and a
 dictionary of attributes to better classify the user.
 
 @param identifier        unique name identifying the user
 @param attributes        dictionary of user attributes
 @param alias             after identifying user, alias/link the previous anonymous user with it
 */

-(void)identifyUserWithIdentifier:(NSString *)identifier attributes:(NSDictionary *)attributes alias:(BOOL)alias;


/*!
 @method
 
 @abstract
 Sets a user attribute for a given key.
 
 @discussion
 This will set an attribute to better classify the user on the
 Liquid analytics. Attribute must be either NSString or NSNumber.
 
 @param attribute         user attribute
 @param key               key to identify the attribute
 */

-(void)setUserAttribute:(id)attribute forKey:(NSString *)key;


/*!
 @method
 
 @abstract
 Sets one or more user attributes (NSDictionary)
 
 @discussion
 This will set one or more attributes to better classify the user on the
 Liquid analytics.
 
 @param attributes        user attributes
 */

- (void)setUserAttributes:(NSDictionary *)attributes;


/*!
 @method
 
 @abstract
 Set the current device location
 
 @discussion
 This will associate GPS coordinates to the device. This is never
 set automatically and must be explicity provided by the developer
 through other methods of obtaining the user location.
 
 @param location          the device location
 */

-(void)setCurrentLocation:(CLLocation *)location;


/*!
 @method
 
 @abstract
 Alias/links two users.
 
 @discussion
 This method alias the previous anonymous user with the current one.
 This means that all data points of the anonymous user with belong to
 the current (identified) one.
 
 */

- (void)aliasUser;


/*!
 @method
 
 @abstract
 Set the push notification APNS device token
 
 @discussion
 This will register device APNS token on Liquid current device,
 which will allow push notifications to be sent from Liquid dashboard.
 
 @param deviceToken          the APNS Devie Token
 */

- (void)setApplePushNotificationToken:(NSData *)deviceToken;


/*!
 @method
 
 @abstract
 Tracks an event on the application.
 
 @discussion
 This will report an event that occurred on the application to the
 Liquid API. A name should be given to identify such event, else it
 will report an 'unnammed_event'.
 
 @param eventName         name to identify the event
 */

-(void)track:(NSString *)eventName;


/*!
 @method
 
 @abstract
 Tracks an event with some attributes on the application.
 
 @discussion
 This will report an event that occurred on the application to the
 Liquid API. A name should be given to identify such event, else it
 will report an 'unnammed_event'. A dictionary of attributes may be
 used to further classify what happened in such event.

 @param eventName         name to identify the event
 @param attributes        dictionary of attributes
 */

-(void)track:(NSString *)eventName attributes:(NSDictionary *)attributes;


/*!
 @method
 
 @abstract
 Request an update to the dynamic variables.
 
 @discussion
 This will trigger a network request to the Liquid API to obtain
 a set of dynamic variables that have been set for this particular
 combination of user, device and session.

 */

-(void)requestValues;


/*!
 @method
 
 @abstract
 Trigger the load of the variables received in requestValues.
 
 @discussion
 Will load the variables received from the Liquid API on to memory, 
 to access them through the ForVariable: methods. Variables may be of
 UIColor, NSDate, NSString or NSNumber.
 */

-(void)loadValues;


/*!
 @method
 
 @abstract
 Get a color dynamic variable from a key.
 
 @discussion
 Will return the color dynamic variable from a provided key.
 This will depend on the user, device and session at the time of the
 last call to requestValues and loadValues.

 @param variableName       the key to identify the variable
 */

-(UIColor *)colorForKey:(NSString *)variableName fallback:(UIColor *)fallbackValue;


/*!
 @method
 
 @abstract
 Get a string dynamic variable from a key.
 
 @discussion
 Will return the string dynamic variable from a provided key.
 This will depend on the user, device and session at the time of the
 last call to requestValues and loadValues.
 
 @param variableName       the key to identify the variable
 */

-(NSString *)stringForKey:(NSString *)variableName fallback:(NSString *)fallbackValue;


/*!
 @method
 
 @abstract
 Get a int dynamic variable from a key.
 
 @discussion
 Will return the int dynamic variable from a provided key.
 This will depend on the user, device and session at the time of the
 last call to requestValues and loadValues.
 
 @param variableName       the key to identify the variable
 */

-(NSInteger)intForKey:(NSString *)variableName fallback:(NSInteger)fallbackValue;


/*!
 @method
 
 @abstract
 Get a float dynamic variable from a key.
 
 @discussion
 Will return the float dynamic variable from a provided key.
 This will depend on the user, device and session at the time of the
 last call to requestValues and loadValues.
 
 @param variableName       the key to identify the variable
 */

-(CGFloat)floatForKey:(NSString *)variableName fallback:(CGFloat)fallbackValue;


/*!
 @method
 
 @abstract
 Get a boolean dynamic variable from a key.
 
 @discussion
 Will return the boolean dynamic variable from a provided key.
 This will depend on the user, device and session at the time of the
 last call to requestValues and loadValues.
 
 @param variableName       the key to identify the variable
 */

-(BOOL)boolForKey:(NSString *)variableName fallback:(BOOL)fallbackValue;


/*!
 @method
 
 @abstract
 Get a date dynamic variable from a key.
 
 @discussion
 Will return the date dynamic variable from a provided key.
 This will depend on the user, device and session at the time of the
 last call to requestValues and loadValues.
 
 @param variableName       the key to identify the variable
 */

-(NSDate *)dateForKey:(NSString *)variableName fallback:(NSDate *)fallbackValue;


/*!
 @method
 
 @abstract
 Force a flush of the pending Liquid API Requests.
 
 @discussion
 This will flush all the pending requests, clearing the queue
 in case of absolute success.
 */

-(void)flush;


/*!
 @method
 
 @abstract
 Soft Reset Liquid SDK.
 
 @discussion
 Will reset all liquid (dynamic variable) to its fallback values. A new session is created, and user attributes are reset.
 */

-(void)softReset;


/*!
 @method
 
 @abstract
 Hard reset Liquid SDK.
 
 @discussion
 Will reset Liquid as soft reset does, but also remove all queued HTTP requests.
 */

-(void)hardReset;

+ (void)softReset;
+ (void)hardResetForApiToken:(NSString *)token;

@end
