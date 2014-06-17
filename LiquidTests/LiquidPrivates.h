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
#import "LQQueue.h"
#import "LQValue.h"
#import "LQTarget.h"
#import "LQDataPoint.h"
#import "LQLiquidPackage.h"
#import "LQDefaults.h"

@protocol LiquidDelegate <NSObject>
@optional
- (void)liquidDidReceiveValues;
- (void)liquidDidLoadValues;
@end

@interface Liquid : NSObject

@property(nonatomic, strong) NSString *apiToken;
@property(nonatomic, assign) BOOL developmentMode;
@property(nonatomic, strong) LQUser *currentUser;
@property(nonatomic, strong) LQDevice *device;
@property(nonatomic, strong) LQSession *currentSession;
@property(nonatomic, strong) NSDate *enterBackgroundTime;
@property(nonatomic, strong) NSDate *veryFirstMoment;
@property(nonatomic, assign) BOOL firstEventSent;
@property(nonatomic, assign) BOOL inBackground;
@property(nonatomic, strong) dispatch_queue_t queue;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, strong) NSMutableArray *httpQueue;
@property(nonatomic, strong) LQLiquidPackage *loadedLiquidPackage; // (includes loaded Targets and loaded Values)
@property(nonatomic, strong, readonly) NSString *liquidUserAgent;

extern NSString * const LQDidReceiveValues;
extern NSString * const LQDidLoadValues;

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
- (NSDate *)veryFirstMoment;
- (BOOL)flushOnBackground;
- (NSUInteger)queueSizeLimit;
- (BOOL)sendFallbackValuesInDevelopmentMode;
- (NSUInteger)flushInterval;
- (void)setFlushInterval:(NSUInteger)interval;
- (NSInteger)sessionTimeout;
- (void)setSessionTimeout:(NSInteger)sessionTimeout;
- (NSString *)liquidUserAgent;

#pragma mark - UIApplication notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification;
- (void)applicationWillResignActive:(NSNotificationCenter *)notification;

#pragma mark - User Interaction

- (void)identifyUser;
- (void)identifyUserWithIdentifier:(NSString *)identifier;
- (void)identifyUserWithIdentifier:(NSString *)identifier attributes:(NSDictionary *)attributes;
- (void)identifyUserWithIdentifier:(NSString *)identifier attributes:(NSDictionary *)attributes location:(CLLocation *)location;
- (void)identifyUserSyncedWithIdentifier:(NSString *)identifier attributes:(NSDictionary *)attributes location:(CLLocation *)location;
- (NSString *)userIdentifier;
- (NSString *)deviceIdentifier;
- (NSString *)sessionIdentifier;
- (void)setUserAttribute:(id)attribute forKey:(NSString *)key;
- (void)setUserLocation:(CLLocation *)location;
+ (void)assertUserAttributeType:(id)attribute;
+ (void)assertUserAttributesTypes:(NSDictionary *)attributes;

#pragma mark - Session

- (void)destroySessionIfExists;
- (void)newSessionInCurrentThread:(BOOL)inThread;
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

- (void)addToHttpQueue:(NSDictionary*)dictionary endPoint:(NSString*)endPoint httpMethod:(NSString*)httpMethod;
- (void)flush;
- (void)startFlushTimer;
- (void)stopFlushTimer;

#pragma mark - Resetting

- (void)softReset;
- (void)hardReset;

#pragma mark - Networking

- (NSInteger)sendData:(NSData *)data toEndpoint:(NSString *)endpoint usingMethod:(NSString *)method;
- (NSData *)getDataFromEndpoint:(NSString *)endpoint;
    
#pragma mark - File Management
    
+ (NSMutableArray*)unarchiveQueueForToken:(NSString*)apiToken;
+ (BOOL)archiveQueue:(NSMutableArray*)queue forToken:(NSString*)apiToken;
+ (BOOL)deleteFileIfExists:(NSString *)fileName error:(NSError **)err;
+ (NSString*)liquidQueueFileForToken:(NSString*)apiToken;
    
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

@end
