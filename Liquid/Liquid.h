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
 Liquid* liquid = [Liquid sharedInstanceWithToken:@"YOUR_API_TOKEN"];
 
 // Identify the user
 [liquid identifyUserWithIdentifier:@"username@lqd.io" withAttributes:[NSDictionary dictionaryWithObjects:@[@"23",@"male"] forKeys:@[@"age",@"sex"]]];
 
 // Set user attribute
 [liquid setUserAttribute:@"irish" forKey:@"nationality"];
 
 // Track an event
 [liquid track:@"purchase_click" withAttributes:[NSDictionary dictionaryWithObjects:@[@"33.89",@"USD"] forKeys:@[@"price",@"currency"]];
 
 // Get variables defined on Liquid
 UIColor* backgroundColor = [liquid colorForVariable:@"tableViewBackgroundColor"];
 [tableView setBackgroundColor:backgroundColor];
 </pre>
 
 For more advanced usage, please see the <a
 href="https://lqd.io/">Liquid iOS
 Library Guide</a>.
 */
@interface Liquid : NSObject

extern NSString * const LQDidReceiveValues;
extern NSString * const LQDidLoadValues;

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
 The base URL used for Liquid API requests.
 
 @discussion
 Useful if you need to proxy Liquid http requests. Defaults to
 http://api.lqd.io/collect/
 */
@property (atomic, copy) NSString *serverURL;

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
 Control whether data should be flushed (or not) when the application
 enters background.
 
 @discussion
 Defaults to YES.
 */
@property (nonatomic, assign) BOOL flushOnBackground;

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
 This avoids the manual load of variables by calling the loadNewValues method.
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
 Returns the previously instantiated singleton instance of the API.
 
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

-(NSString*)userIdentifier;
/*!
 @method
 
 @abstract
 Automatically identifies the user on to the Liquid API.
 
 @discussion
 This will identify the user either by the advertising identifier or
 the uuid of the device.
 */

-(void)identifyUser;
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
 Identifies the user on to the Liquid API with a given identifier and some
 attributes.
 
 @discussion
 This will identify the user with the given identifier string and a 
 dictionary of attributes to better classify the user.
 
 @param identifier        unique name identifying the user
 @param attributes        dictionary of user attributes
 */

-(void)identifyUserWithIdentifier:(NSString *)identifier withAttributes:(NSDictionary *)attributes;
/*!
 @method
 
 @abstract
 Identifies the user on to the Liquid API with a given identifier, some
 attributes and a user location.
 
 @discussion
 This will identify the user with the given identifier string, a
 dictionary of attributes to better classify the user and a CLLocation
 to better pin point where the user is using the application. This is never
 calculated automatically and must be explicity provided by the developer
 through other methods of obtaining the user location.
 
 @param identifier        unique name identifying the user
 @param attributes        dictionary of user attributes
 @param location          user location
 */

-(void)identifyUserWithIdentifier:(NSString *)identifier withAttributes:(NSDictionary *)attributes withLocation:(CLLocation *)location;
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
 Set the user location
 
 @discussion
 This will associate GPS coordinates to the user. This is never
 set automatically and must be explicity provided by the developer
 through other methods of obtaining the user location.
 
 @param location          the user location
 */

-(void)setUserLocation:(CLLocation *)location;

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

-(void)track:(NSString *)eventName withAttributes:(NSDictionary *)attributes;

/*!
 @method
 
 @abstract
 Request an update to the dynamic variables.
 
 @discussion
 This will trigger a network request to the Liquid API to obtain
 a set of dynamic variables that have been set for this particular
 combination of user, device and session.

 */

-(void)requestNewValues;
/*!
 @method
 
 @abstract
 Trigger the load of the variables received in requestNewValues.
 
 @discussion
 Will load the variables received from the Liquid API on to memory, 
 to access them through the ForVariable: methods. Variables may be of
 UIColor, NSDate, NSString or NSNumber.
 */

-(void)loadNewValues;

/*!
 @method
 
 @abstract
 Get a color dynamic variable from a key.
 
 @discussion
 Will return the color dynamic variable from a provided key.
 This will depend on the user, device and session at the time of the
 last call to requestNewValues and loadNewValues.

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
 last call to requestNewValues and loadNewValues.
 
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
 last call to requestNewValues and loadNewValues.
 
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
 last call to requestNewValues and loadNewValues.
 
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
 last call to requestNewValues and loadNewValues.
 
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
 last call to requestNewValues and loadNewValues.
 
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

@end
