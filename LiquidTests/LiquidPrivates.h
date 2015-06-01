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

#import "LQEvent.h"
#import "LQSession.h"
#import "LQDevice.h"
#import "LQUser.h"
#import "LQRequest.h"
#import "LQValue.h"
#import "LQTarget.h"
#import "LQDataPoint.h"
#import "LQLiquidPackage.h"
#import "LQDefaults.h"
#import "LQNetworkingPrivates.h"

@protocol LiquidDelegate <NSObject>
@optional
- (void)liquidDidReceiveValues;
- (void)liquidDidLoadValues;
- (void)liquidDidIdentifyUserWithIdentifier:(NSString *)identifier;
@end

@interface Liquid : NSObject

extern NSString * const LQDidReceiveValues;
extern NSString * const LQDidLoadValues;
extern NSString * const LQDidIdentifyUser;

@property (atomic, retain) NSObject<LiquidDelegate> *delegate;
@property (atomic, copy) NSString *serverURL;
@property (nonatomic) NSUInteger flushInterval;
@property (nonatomic, assign) BOOL sendFallbackValuesInDevelopmentMode;
@property (nonatomic, assign) NSUInteger queueSizeLimit;
@property (atomic) BOOL autoLoadValues;
@property (nonatomic, assign) NSInteger sessionTimeout;

@property(nonatomic, strong) NSString *apiToken;
@property(nonatomic, assign) BOOL developmentMode;
@property(atomic, strong) LQUser *currentUser;
@property(atomic, strong) LQUser *previousUser;
@property(atomic, strong) LQDevice *device;
@property(atomic, strong) LQSession *currentSession;
@property(nonatomic, strong) NSDate *enterBackgroundTime;
@property(nonatomic, assign) BOOL inBackground;
#if OS_OBJECT_USE_OBJC
@property(atomic, strong) dispatch_queue_t queue;
#else
@property(atomic, assign) dispatch_queue_t queue;
#endif
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, strong) NSMutableArray *httpQueue;
@property(nonatomic, strong) LQLiquidPackage *loadedLiquidPackage; // (includes loaded Targets and loaded Values)
@property(nonatomic, strong, readonly) NSString *liquidUserAgent;
@property(nonatomic, strong) NSNumber *uniqueNowIncrement;
@property(nonatomic, strong) LQNetworking *networking;

#pragma mark - Singletons

+ (Liquid *)sharedInstanceWithToken:(NSString *)apiToken;
+ (Liquid *)sharedInstanceWithToken:(NSString *)apiToken development:(BOOL)development;
+ (Liquid *)sharedInstance;

#pragma mark - Initialization

- (instancetype)initWithToken:(NSString *)apiToken;
- (void)invalidateTargetThatIncludesVariable:(NSString *)variableName;
- (instancetype)initWithToken:(NSString *)apiToken development:(BOOL)development;

#pragma mark - Lazy initialization

- (BOOL)inBackground;
- (NSUInteger)queueSizeLimit;
- (BOOL)sendFallbackValuesInDevelopmentMode;
- (NSUInteger)flushInterval;
- (void)setFlushInterval:(NSUInteger)interval;
- (NSInteger)sessionTimeout;
- (void)setSessionTimeout:(NSInteger)sessionTimeout;
- (NSString *)liquidUserAgent;

#pragma mark - UIApplication notifications

- (void)applicationWillEnterForeground:(NSNotification *)notification;
- (void)applicationDidEnterBackground:(NSNotificationCenter *)notification;

#pragma mark - User Interaction

- (void)resetUser;
- (void)identifyUser;
- (void)identifyUserWithIdentifier:(NSString *)identifier;
- (void)identifyUserWithIdentifier:(NSString *)identifier alias:(BOOL)alias;
- (void)identifyUserWithIdentifier:(NSString *)identifier attributes:(NSDictionary *)attributes;
- (void)identifyUserWithIdentifier:(NSString *)identifier attributes:(NSDictionary *)attributes alias:(BOOL)alias;
- (void)identifyUser:(LQUser *)user alias:(BOOL)alias;
- (void)aliasUser;
- (void)aliasUser:(LQUser *)user withIdentifier:(NSString *)newIdentifier;

- (NSString *)userIdentifier;
- (NSString *)deviceIdentifier;
- (NSString *)sessionIdentifier;
- (void)setUserAttribute:(id)attribute forKey:(NSString *)key;
- (void)setUserAttributes:(NSDictionary *)attributes;
- (void)setUserLocation:(CLLocation *)location;
+ (void)assertUserAttributeType:(id)attribute;
+ (void)assertUserAttributesTypes:(NSDictionary *)attributes;

#pragma mark - Session

- (void)destroySessionIfExists;
- (void)startSession;
- (BOOL)checkSessionTimeout;

#pragma mark - Event

- (void)track:(NSString *)eventName;
- (void)track:(NSString *)eventName attributes:(NSDictionary *)attributes;
- (void)track:(NSString *)eventName attributes:(NSDictionary *)attributes allowLqdEvents:(BOOL)allowLqdEvents;

#pragma mark - Liquid Package

- (LQLiquidPackage *)requestNewLiquidPackageSynced;
- (void)requestNewLiquidPackage;
- (void)requestValues;
- (void)notifyDelegatesAndObserversAboutNewValues;
- (LQLiquidPackage *)loadLiquidPackageFromDisk;
- (void)loadLiquidPackageSynced:(BOOL)synced;
- (void)loadValues;

#pragma mark - Development functionalities

- (void)sendVariable:(NSString *)variableName fallback:(id)fallbackValue liquidType:(NSString *)typeString;

#pragma mark - Values with Data Types

- (NSDate *)dateForKey:(NSString *)variableName fallback:(NSDate *)fallbackValue;
- (UIColor *)colorForKey:(NSString *)variableName fallback:(UIColor *)fallbackValue;
- (NSString *)stringForKey:(NSString *)variableName fallback:(NSString *)fallbackValue;
- (NSInteger)intForKey:(NSString *)variableName fallback:(NSInteger)fallbackValue;
- (CGFloat)floatForKey:(NSString *)variableName fallback:(CGFloat)fallbackValue;
- (BOOL)boolForKey:(NSString *)variableName fallback:(BOOL)fallbackValue;

#pragma mark - Queueing

- (void)flush;
- (void)startFlushTimer;
- (void)stopFlushTimer;

#pragma mark - Resetting

- (void)softReset;
- (void)hardReset;

#pragma mark - Networking

- (NSInteger)sendData:(NSData *)data toEndpoint:(NSString *)endpoint usingMethod:(NSString *)method;
- (NSData *)getDataFromEndpoint:(NSString *)endpoint;
    
#pragma mark - Static Helpers
    
+ (void)assertEventAttributesTypes:(NSDictionary *)attributes;
+ (id)fromJSON:(NSData *)data;
+ (NSData*)toJSON:(NSDictionary *)object;
+ (NSDictionary *)normalizeDataTypes:(NSDictionary *)dictionary;
    
#pragma mark - Liquid Helpers
    
+ (NSData *)randomDataOfLength:(size_t)length;
+ (NSString *)generateRandomUniqueId;

+ (void)destroySingleton;
+ (void)softReset;
+ (void)hardResetForApiToken:(NSString *)token;

- (NSDate *)uniqueNow;
- (void)saveCurrentUserToDisk;
- (LQUser *)loadLastUserFromDisk;
- (void)beginBackgroundUpdateTask;
- (void)endBackgroundUpdateTask;

@end
