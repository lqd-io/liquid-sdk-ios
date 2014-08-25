//
//  Liquid.m
//  Liquid
//
//  Created by Liquid Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "Liquid.h"

#import <UIKit/UIApplication.h>

#import "LQEvent.h"
#import "LQSession.h"
#import "LQDevice.h"
#import "LQUser.h"
#import "LQRequest.h"
#import "LQVariable.h"
#import "LQValue.h"
#import "LQTarget.h"
#import "LQDataPoint.h"
#import "LQLiquidPackage.h"
#import "LQDefaults.h"
#import "LQDate.h"
#import "UIColor+LQColor.h"
#import "NSDateFormatter+LQDateFormatter.h"
#import "NSString+LQString.h"
#import "NSData+LQData.h"
#import "LQNetworking.h"

#if !__has_feature(objc_arc)
#  error Compile me with ARC, please!
#endif

@interface Liquid ()

@property(nonatomic, strong) NSString *apiToken;
@property(nonatomic, assign) BOOL developmentMode;
@property(nonatomic, strong) LQUser *currentUser;
@property(nonatomic, strong) LQUser *previousUser;
@property(nonatomic, strong) LQDevice *device;
@property(nonatomic, strong) LQSession *currentSession;
@property(nonatomic, strong) NSDate *enterBackgroundTime;
@property(nonatomic, assign) UIBackgroundTaskIdentifier backgroundUpdateTask;
@property(nonatomic, strong) LQLiquidPackage *loadedLiquidPackage; // (includes loaded Targets and loaded Values)
@property(nonatomic, strong) NSMutableArray *valuesSentToServer;
@property(nonatomic, strong) LQNetworking *networking;
#if OS_OBJECT_USE_OBJC
@property(nonatomic, strong) dispatch_queue_t queue;
#else
@property(nonatomic, assign) dispatch_queue_t queue;
#endif

@end

static Liquid *sharedInstance = nil;

@implementation Liquid

@synthesize autoLoadValues = _autoLoadValues;
@synthesize queueSizeLimit = _queueSizeLimit;
@synthesize sessionTimeout = _sessionTimeout;
@synthesize sendFallbackValuesInDevelopmentMode = _sendFallbackValuesInDevelopmentMode;
@synthesize valuesSentToServer = _valuesSentToServer;
@synthesize networking = _networking;

NSString * const LQDidReceiveValues = kLQNotificationLQDidReceiveValues;
NSString * const LQDidLoadValues = kLQNotificationLQDidLoadValues;
NSString * const LQDidIdentifyUser = kLQNotificationLQDidIdentifyUser;

#pragma mark - Singletons

+ (Liquid *)sharedInstanceWithToken:(NSString *)apiToken {
    return [Liquid sharedInstanceWithToken:apiToken development:NO];
}

+ (Liquid *)sharedInstanceWithToken:(NSString *)apiToken development:(BOOL)development {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc] initWithToken:apiToken development:development];
    });
    return sharedInstance;
}

+ (Liquid *)sharedInstance {
    if (sharedInstance == nil) {
        NSAssert(false, @"<Liquid> Error: %@ sharedInstance called before sharedInstanceWithToken:", self);
        LQLog(kLQLogLevelError, @"<Liquid> Error: %@ sharedInstance called before sharedInstanceWithToken:", self);
    }
    return sharedInstance;
}

#pragma mark - HTTP Queue

- (void)setQueueSizeLimit:(NSUInteger)queueSizeLimit {
    [_networking setQueueSizeLimit:queueSizeLimit];
}

- (void)setFlushInterval:(NSUInteger)interval {
    [_networking setFlushInterval:interval];
}

- (void)flush {
    dispatch_async(self.queue, ^{
        [_networking flush];
    });
}

#pragma mark - Initialization

- (instancetype)initWithToken:(NSString *)apiToken {
    return [self initWithToken:apiToken development:NO];
}

- (instancetype)initWithToken:(NSString *)apiToken development:(BOOL)development {
    if (development) {
        _developmentMode = YES;
    } else {
        _developmentMode = NO;
    }
    if (apiToken == nil) apiToken = @"";
    if ([apiToken length] == 0) {
        NSAssert(false, @"<Liquid> Error: %@ empty API Token", self);
        LQLog(kLQLogLevelError, @"<Liquid> Error: %@ empty API Token", self);
    }
    if (self = [self init]) {
        self.apiToken = apiToken;
        self.networking = [[LQNetworking alloc] initFromDiskWithToken:self.apiToken];
        self.device = [LQDevice sharedInstance];
        self.sessionTimeout = kLQDefaultSessionTimeout;
        _sendFallbackValuesInDevelopmentMode = kLQSendFallbackValuesInDevelopmentMode;
        NSString *queueLabel = [NSString stringWithFormat:@"%@.%@.%p", kLQBundle, apiToken, self];
        self.queue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        self.backgroundUpdateTask = UIBackgroundTaskInvalid;
        if(!_loadedLiquidPackage) {
            [self loadLiquidPackageSynced:YES];
        }

        // Load user from previous launch:
        _previousUser = [self loadLastUserFromDisk];
        [self autoIdentifyUser];
        if (!self.currentSession) {
            [self startSession];
        }

        // Start auto flush timer
        [_networking startFlushTimer];

        // Bind notifications:
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(applicationWillEnterForeground:)
                                   name:UIApplicationWillEnterForegroundNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(applicationDidEnterBackground:)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(applicationWillTerminate:)
                                   name:UIApplicationWillTerminateNotification
                                 object:nil];

        LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Initialized Liquid with API Token %@", apiToken);
    }
    return self;
}

#pragma mark - Lazy initialization

- (void)setSessionTimeout:(NSInteger)sessionTimeout {
    @synchronized(self) {
        _sessionTimeout = sessionTimeout;
    }
}

- (NSArray *)valuesSentToServer {
    if (!_valuesSentToServer) {
        _valuesSentToServer = [[NSMutableArray alloc] init];
    }
    return _valuesSentToServer;
}

#pragma mark - UIApplication notifications

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    [LQDate resetUniqueNow];
    if ([self checkSessionTimeout]) {
        if ([self.currentSession inProgress]) {
            [self endSessionAt:self.enterBackgroundTime];
        }
        [self startSession];
    } else {
        [self resumeSession];
    }
    [_networking startFlushTimer];
    [self loadLiquidPackageSynced:YES];
}

- (void)applicationDidEnterBackground:(NSNotificationCenter *)notification {
    NSDate *date = [LQDate uniqueNow];
    [self beginBackgroundUpdateTask];
    [self track:@"_pauseSession" attributes:nil allowLqdEvents:YES withDate:date];
    self.enterBackgroundTime = [LQDate uniqueNow];
    [_networking stopFlushTimer];
    [self flush];
    [self requestNewLiquidPackageSynced];
    dispatch_async(self.queue, ^{
        [self endBackgroundUpdateTask];
    });
}

- (void)applicationWillTerminate:(NSNotificationCenter *)notification {
    [self endSessionNow];
}

- (void)beginBackgroundUpdateTask {
    self.backgroundUpdateTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:kLQBackgroundTaskName expirationHandler:^{
        [self endBackgroundUpdateTask];
    }];
}

- (void)endBackgroundUpdateTask {
    if (self.backgroundUpdateTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundUpdateTask];
        self.backgroundUpdateTask = UIBackgroundTaskInvalid;
    }
}

#pragma mark - User identifying methods (real methods)

- (void)identifyUserWithIdentifier:(NSString *)identifier attributes:(NSDictionary *)attributes alias:(BOOL)alias {
    NSDictionary *validAttributes = [LQUser assertAttributesTypesAndKeys:attributes];
    if (identifier && identifier.length == 0) {
        LQLog(kLQLogLevelError, @"<Liquid> Error (%@): No User identifier was given: %@", self, identifier);
        return;
    }
    LQUser *newUser = [[LQUser alloc] initWithIdentifier:[identifier copy] attributes:[validAttributes copy]];
    [self identifyUserSynced:newUser alias:alias];
}

- (void)identifyUserSynced:(LQUser *)user alias:(BOOL)alias {
    self.previousUser = self.currentUser;
    LQUser *newUser = [user copy];
    LQUser *currentUser = [self.currentUser copy];
    if ([newUser.identifier isEqualToString:currentUser.identifier]) {
        self.currentUser.attributes = newUser.attributes; // just updating current user attributes
        LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Already identified with user %@. Not identifying again.", user.identifier);
    } else {
        [self endSessionNow];
        self.currentUser = newUser;
        [self startSession];
    }
    [self saveCurrentUserToDisk];
    [self requestNewLiquidPackage];

    // Notifiy the outside world:
    NSDictionary *notificationUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:newUser, @"identifier", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:LQDidIdentifyUser object:nil userInfo:notificationUserInfo];
    if([self.delegate respondsToSelector:@selector(liquidDidIdentifyUserWithIdentifier:)]) {
        [self.delegate performSelectorOnMainThread:@selector(liquidDidIdentifyUserWithIdentifier:)
                                        withObject:newUser.identifier
                                     waitUntilDone:NO];
    }

    if (alias && ![newUser.identifier isEqualToString:currentUser.identifier]) {
        [self aliasUser];
    }
    LQLog(kLQLogLevelInfo, @"<Liquid> From now on, we're identifying the User by identifier '%@'", newUser.identifier);
}

#pragma mark - User identifying methods (alias methods)

// Deprecated:
- (void)identifyUser {
    [self resetUser];
}

// Deprecated:
- (void)identifyUserWithAttributes:(NSDictionary *)attributes {
    [self identifyUserWithIdentifier:nil attributes:[LQUser assertAttributesTypesAndKeys:attributes] alias:NO];
}

// Deprecated:
- (void)identifyUserWithIdentifier:(NSString *)identifier attributes:(NSDictionary *)attributes location:(CLLocation *)location {
    [self identifyUserWithIdentifier:identifier attributes:attributes alias:YES];
    dispatch_async(self.queue, ^() {
        [self setCurrentLocation:location];
    });
}

- (void)autoIdentifyUser {
    if (self.previousUser) {
        [self identifyUserSynced:_previousUser alias:NO];
        LQLog(kLQLogLevelInfo, @"<Liquid> Identifying user (using cached user: %@)", _previousUser.identifier);
    } else {
        [self identifyUserWithIdentifier:nil attributes:nil alias:NO];
        LQLog(kLQLogLevelInfo, @"<Liquid> Identifying user anonymously: creating a new anonymous user (%@)", _currentUser.identifier);
    }
}

- (void)resetUser {
    [self identifyUserWithIdentifier:nil attributes:nil alias:NO];
}

- (void)identifyUserWithIdentifier:(NSString *)identifier {
    [self identifyUserWithIdentifier:identifier attributes:nil alias:YES];
}

- (void)identifyUserWithIdentifier:(NSString *)identifier attributes:(NSDictionary *)attributes {
    [self identifyUserWithIdentifier:identifier attributes:attributes alias:YES];
}

- (void)identifyUserWithIdentifier:(NSString *)identifier alias:(BOOL)alias {
    [self identifyUserWithIdentifier:identifier attributes:nil alias:alias];
}

- (void)identifyUserSynced:(LQUser *)user {
    [self identifyUserSynced:user alias:YES];
}

#pragma mark - User related stuff

- (NSString *)userIdentifier {
    if(self.currentUser == nil) {
        LQLog(kLQLogLevelError, @"<Liquid> Error: A user has not been identified yet.");
    }
    return self.currentUser.identifier;
}

- (NSString *)deviceIdentifier {
    return [self.device uid];
}

- (void)setUserAttribute:(id)attribute forKey:(NSString *)key {
    if (![LQUser assertAttributeType:attribute andKey:key]) return;

    dispatch_async(self.queue, ^() {
        if(self.currentUser == nil) {
            LQLog(kLQLogLevelError, @"<Liquid> Error: A user has not been identified yet.");
            return;
        }
        [self.currentUser setAttribute:attribute
                                forKey:key];
        [self saveCurrentUserToDisk];
    });
}

// Deprecated:
- (void)setUserLocation:(CLLocation *)location {
    [self setCurrentLocation:location];
}

- (void)setCurrentLocation:(CLLocation *)location {
    dispatch_async(self.queue, ^() {
        if(self.currentUser == nil) {
            LQLog(kLQLogLevelError, @"<Liquid> Error: A user has not been identified yet.");
            return;
        }
        [self.device setLocation:location];
    });
}

- (void)saveCurrentUserToDisk {
    __block LQUser *user = [self.currentUser copy];
    dispatch_async(self.queue, ^() {
        [user saveToDiskForToken:_apiToken];
    });
}

- (LQUser *)loadLastUserFromDisk {
    LQUser *user = [LQUser loadFromDiskForToken:_apiToken];
    self.currentUser = [user copy];
    return user;
}

#pragma mark - User aliasing of anonymous users

- (void)aliasUser {
    LQUser *previousUser = [self.previousUser copy];
    if (![previousUser isIdentified]) {
        [self aliasUser:previousUser withIdentifier:self.currentUser.identifier];
    } else {
        LQLog(kLQLogLevelError, @"<Liquid> Error: Previous user is an identified user. You can only alias anonymous (non-identified) with identified users.");
    }
}

- (void)aliasUser:(LQUser *)user withIdentifier:(NSString *)newIdentifier {
    __block LQUser *anonymousUser = [user copy];
    __block NSString *newUserIdentifier = [newIdentifier copy];
    if ([anonymousUser isIdentified]) {
        LQLog(kLQLogLevelError, @"<Liquid> Error: You're trying to reidentify an already identified user %@. It is only possible to reidentify non identified users", anonymousUser.identifier);
        return;
    }
    LQLog(kLQLogLevelInfo, @"<Liquid> Reidentifying anonymous user (%@) with a new identifier (%@)", anonymousUser.identifier, newUserIdentifier);
    dispatch_async(self.queue, ^{
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:newIdentifier, @"unique_id", anonymousUser.identifier, @"unique_id_alias", nil];
        [_networking addToHttpQueue:params
                    endPoint:@"aliases"
                  httpMethod:@"POST"];
    });
}

#pragma mark - Sessions

- (void)setApplePushNotificationToken:(NSData *)deviceToken {
    NSString *hexToken = [[deviceToken copy] hexadecimalString];
    if (hexToken) {
        self.device.apnsToken = hexToken;
        NSString *apnsTokenCacheKey = [NSString stringWithFormat:@"%@.%@", kLQBundle, @"APNSToken"];
        [[NSUserDefaults standardUserDefaults] setObject:hexToken forKey:apnsTokenCacheKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)endSessionAt:(NSDate *)endAt {
    NSDate *endAtDate = [endAt copy];
    if (self.currentUser != nil && self.currentSession != nil && self.currentSession.inProgress) {
        [[self currentSession] endSessionOnDate:endAtDate];
        [self track:@"_endSession" attributes:nil allowLqdEvents:YES withDate:endAtDate];
        LQLog(kLQLogLevelInfo, @"Ended session %@ for user %@ (%@) at %@", self.currentSession.identifier, self.currentUser.identifier, (self.currentUser.isIdentified ? @"identified" : @"anonymous"), [NSDateFormatter iso8601StringFromDate:endAtDate]);
    }
}

- (void)endSessionNow {
    [self endSessionAt:[LQDate uniqueNow]];
}

- (void)startSession {
    NSDate *now = [LQDate uniqueNow];
    self.currentSession = [[LQSession alloc] initWithDate:now timeout:[NSNumber numberWithInt:(int)_sessionTimeout]];
    [self track:@"_startSession" attributes:nil allowLqdEvents:YES withDate:now];
    LQLog(kLQLogLevelInfo, @"Started session %@ for user %@ (%@) at %@", self.currentSession.identifier, self.currentUser.identifier, (self.currentUser.isIdentified ? @"identified" : @"anonymous"), [NSDateFormatter iso8601StringFromDate:now]);
}

- (void)resumeSession {
    NSDate *now = [LQDate uniqueNow];
    [self track:@"_resumeSession" attributes:nil allowLqdEvents:YES withDate:now];
    LQLog(kLQLogLevelInfo, @"Resumed session %@ for user %@ (%@) at %@", self.currentSession.identifier, self.currentUser.identifier, (self.currentUser.isIdentified ? @"identified" : @"anonymous"), [NSDateFormatter iso8601StringFromDate:now]);
}

- (BOOL)checkSessionTimeout {
    if(self.currentSession != nil) {
        NSDate *now = [LQDate uniqueNow];
        NSTimeInterval interval = [now timeIntervalSinceDate:self.enterBackgroundTime];
        if(interval >= _sessionTimeout) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)sessionIdentifier {
    return self.currentSession.identifier;
}

#pragma mark - Events

- (void)track:(NSString *)eventName {
    [self track:eventName attributes:nil allowLqdEvents:NO];
}

- (void)track:(NSString *)eventName attributes:(NSDictionary *)attributes {
    NSDictionary *validAttributes = [LQEvent assertAttributesTypesAndKeys:attributes];

    [self track:eventName attributes:validAttributes allowLqdEvents:NO];
}

- (void)track:(NSString *)eventName attributes:(NSDictionary *)attributes allowLqdEvents:(BOOL)allowLqdEvents {
    [self track:eventName attributes:attributes allowLqdEvents:allowLqdEvents withDate:nil];
}

- (void)track:(NSString *)eventName attributes:(NSDictionary *)attributes allowLqdEvents:(BOOL)allowLqdEvents withDate:(NSDate *)eventDate {
    __block NSDictionary *validAttributes = [LQEvent assertAttributesTypesAndKeys:attributes];

    if([eventName hasPrefix:@"_"] && !allowLqdEvents) {
        NSAssert(false, @"<Liquid> Event names cannot start with _");
        LQLog(kLQLogLevelAssert, @"<Liquid> Event names cannot start with _");
        return;
    }

    if(!self.currentUser) {
        LQLog(kLQLogLevelError, @"<Liquid> No user identified yet.");
        return;
    }
    if(!self.currentSession) {
        LQLog(kLQLogLevelError, @"<Liquid> No session started yet.");
        return;
    }

    __block NSDate *now;
    if (eventDate) {
        now = [eventDate copy];
    } else {
        now = [LQDate uniqueNow];
    }
    
    if ([eventName hasPrefix:@"_"]) {
        LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Tracking Liquid event %@ (%@)", eventName, [NSDateFormatter iso8601StringFromDate:now]);
    } else {
        LQLog(kLQLogLevelInfo, @"<Liquid> Tracking event %@ (%@)", eventName, [NSDateFormatter iso8601StringFromDate:now]);
    }
    
    __block NSString *finalEventName = eventName;
    if (eventName == nil || [eventName length] == 0) {
        LQLog(kLQLogLevelInfo, @"<Liquid> Tracking unnammed event.");
        finalEventName = @"unnamedEvent";
    }
    __block __strong LQEvent *event = [[LQEvent alloc] initWithName:finalEventName attributes:validAttributes date:now];
    __block __strong LQUser *user = [self.currentUser copy];
    __block __strong LQDevice *device = [self.device copy];
    __block __strong LQSession *session = [self.currentSession copy];
    __block __strong NSArray *loadedValues = [_loadedLiquidPackage.values copy];
    dispatch_async(self.queue, ^{
        LQDataPoint *dataPoint = [[LQDataPoint alloc] initWithDate:now
                                                              user:user
                                                            device:device
                                                           session:session
                                                             event:event
                                                            values:loadedValues];
        [_networking addToHttpQueue:[dataPoint jsonDictionary]
                endPoint:@"data_points"
              httpMethod:@"POST"];
    });
}

#pragma mark - Liquid Package

- (LQLiquidPackage *)requestNewLiquidPackageSynced {
    if(!self.currentUser) {
        LQLog(kLQLogLevelInfoVerbose, @"<Liquid> A user has not been identified yet.");
        return nil;
    }
    if(!self.currentSession) {
        LQLog(kLQLogLevelInfoVerbose, @"<Liquid> No session is open yet.");
        return nil;
    }
    NSString *endPoint = [NSString stringWithFormat:@"users/%@/devices/%@/liquid_package", self.currentUser.identifier, self.device.uid, nil];
    NSData *dataFromServer = [_networking getDataFromEndpoint:endPoint];
    LQLiquidPackage *liquidPackage = nil;
    if(dataFromServer != nil) {
        NSDictionary *liquidPackageDictionary = [NSData fromJSON:dataFromServer];
        if(liquidPackageDictionary == nil) {
            return nil;
        }
        liquidPackage = [[LQLiquidPackage alloc] initFromDictionary:liquidPackageDictionary];
        [liquidPackage saveToDiskForToken:_apiToken];

        [[NSNotificationCenter defaultCenter] postNotificationName:LQDidReceiveValues object:nil];
        if([self.delegate respondsToSelector:@selector(liquidDidReceiveValues)]) {
            [self.delegate performSelectorOnMainThread:@selector(liquidDidReceiveValues)
                                            withObject:nil
                                         waitUntilDone:NO];
        }
        if(_autoLoadValues) {
            [self loadLiquidPackageSynced:NO];
        }
    }
    return liquidPackage;
}

- (void)requestNewLiquidPackage {
    dispatch_async(self.queue, ^{
        [self requestNewLiquidPackageSynced];
    });
}

- (void)requestValues {
    [self requestNewLiquidPackage];
}

- (LQLiquidPackage *)loadLiquidPackageFromDisk {
    // Ensure legacy:
    if (_loadedLiquidPackage && ![_loadedLiquidPackage liquidVersion]) {
        LQLog(kLQLogLevelNone, @"<Liquid> SDK was updated: destroying cached Liquid Package to ensure legacy");
        [LQLiquidPackage destroyCachedLiquidPackageForToken:_apiToken];
    }

    LQLiquidPackage *cachedLiquidPackage = [LQLiquidPackage loadFromDiskForToken:_apiToken];
    if (cachedLiquidPackage) {
        return cachedLiquidPackage;
    }
    return [[LQLiquidPackage alloc] initWithValues:[[NSArray alloc] initWithObjects:nil]];
}

- (void)loadLiquidPackageSynced:(BOOL)synced {
    if (synced) {
        _loadedLiquidPackage = [self loadLiquidPackageFromDisk];
        [self notifyDelegatesAndObserversAboutNewValues];
    } else {
        dispatch_async(self.queue, ^{
            _loadedLiquidPackage = [self loadLiquidPackageFromDisk];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self notifyDelegatesAndObserversAboutNewValues];
            });
        });
    }
}

- (void)loadValues {
    [self loadLiquidPackageSynced:NO];
}

- (void)notifyDelegatesAndObserversAboutNewValues {
    NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:[_loadedLiquidPackage dictOfVariablesAndValues], @"values", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:LQDidLoadValues object:nil userInfo:userInfo];
    if([self.delegate respondsToSelector:@selector(liquidDidLoadValues)]) {
        [self.delegate performSelectorOnMainThread:@selector(liquidDidLoadValues)
                                        withObject:nil
                                     waitUntilDone:NO];
    }
    LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Loaded Values: %@", [_loadedLiquidPackage dictOfVariablesAndValues]);
}

#pragma mark - Development functionalities

- (void)sendVariable:(NSString *)variableName fallback:(id)fallbackValue liquidType:(NSString *)typeString {
    dispatch_async(self.queue, ^{
        if ([self.valuesSentToServer indexOfObject:variableName] == NSNotFound) {
            [self.valuesSentToServer addObject:variableName];
            NSDictionary *variable = [[NSDictionary alloc] initWithObjectsAndKeys:variableName, @"name",
                                      typeString, @"data_type",
                                      (fallbackValue?fallbackValue:[NSNull null]), @"default_value", nil];
            NSData *json = [NSData toJSON:variable];
            LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Sending fallback Variable to server: %@", [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]);
            NSInteger res = [_networking sendData:json
                                       toEndpoint:@"variables"
                                      usingMethod:@"POST"];
            if(res != LQQueueStatusOk) LQLog(kLQLogLevelHttp, @"<Liquid> Could not send variables to server %@", [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]);
        }
    });
}

#pragma mark - Targets

- (void)invalidateTargetThatIncludesVariable:(NSString *)variableName {
    __block __strong LQLiquidPackage *loadedLiquidPackage;
    @synchronized(_loadedLiquidPackage) {
        loadedLiquidPackage = [_loadedLiquidPackage copy];
    }
    NSInteger numberOfInvalidatedValues = [loadedLiquidPackage invalidateTargetThatIncludesVariable:variableName];
    @synchronized(_loadedLiquidPackage) {
        _loadedLiquidPackage = loadedLiquidPackage;
    }
    
    if (numberOfInvalidatedValues > 0) {
        LQLiquidPackage *liquidPackageToStore = [loadedLiquidPackage copy];
        dispatch_async(self.queue, ^() {
            [liquidPackageToStore saveToDiskForToken:_apiToken];
        });
    }
    
    if (numberOfInvalidatedValues > 1) { // if included on a target
        dispatch_async(dispatch_get_main_queue(), ^{
            [self notifyDelegatesAndObserversAboutNewValues];
        });
    }
}

#pragma mark - Values with Data Types

- (NSDate *)dateForKey:(NSString *)variableName fallback:(NSDate *)fallbackValue {
    if(_developmentMode && self.sendFallbackValuesInDevelopmentMode && fallbackValue) {
        [self sendVariable:variableName fallback:fallbackValue liquidType:kLQDataTypeDateTime];
    }

    NSError *error;
    LQValue *value = [_loadedLiquidPackage valueForKey:variableName error:&error];
    if(error == nil) {
        if(value == nil) {
            return nil;
        }
        if([value.variable matchesLiquidType:kLQDataTypeDateTime]) {
            NSDate *date = [NSDateFormatter dateFromISO8601String:value.value];
            if(!date) {
                [self invalidateTargetThatIncludesVariable:variableName];
                return fallbackValue;
            }
            return date;
        }
    }
    [self invalidateTargetThatIncludesVariable:variableName];
    return fallbackValue;
}

- (UIColor *)colorForKey:(NSString *)variableName fallback:(UIColor *)fallbackValue {
    if(_developmentMode && self.sendFallbackValuesInDevelopmentMode && fallbackValue) {
        [self sendVariable:variableName fallback:fallbackValue liquidType:kLQDataTypeColor];
    }
    
    NSError *error;
    LQValue *value = [_loadedLiquidPackage valueForKey:variableName error:&error];
    if(error == nil) {
        if(value == nil)
            return nil;
        if([value.variable matchesLiquidType:kLQDataTypeColor]) {
            @try {
                id color = [UIColor colorFromHexadecimalString:value.value];
                if([color isKindOfClass:[UIColor class]]) {
                    return color;
                }
                [self invalidateTargetThatIncludesVariable:variableName];
                return fallbackValue;
            }
            @catch (NSException *exception) {
                LQLog(kLQLogLevelError, @"<Liquid> Variable '%@' value cannot be converted to a color: <%@> %@", variableName, exception.name, exception.reason);
                [self invalidateTargetThatIncludesVariable:variableName];
                return fallbackValue;
            }
        }
    }
    [self invalidateTargetThatIncludesVariable:variableName];
    return fallbackValue;
}

- (NSString *)stringForKey:(NSString *)variableName fallback:(NSString *)fallbackValue {
    NSString *variable = [variableName copy];
    if(_developmentMode && self.sendFallbackValuesInDevelopmentMode && fallbackValue) {
        [self sendVariable:variable fallback:fallbackValue liquidType:kLQDataTypeString];
    }

    NSError *error;
    LQValue *value = [_loadedLiquidPackage valueForKey:variable error:&error];
    if(error == nil) {
        if(value == nil) {
            return nil;
        }
        if([value.variable matchesLiquidType:kLQDataTypeString]) {
            return value.value;
        }
    }
    [self invalidateTargetThatIncludesVariable:variable];
    return fallbackValue;
}

- (NSInteger)intForKey:(NSString *)variableName fallback:(NSInteger)fallbackValue {
    NSString *variable = [variableName copy];
    if(_developmentMode && self.sendFallbackValuesInDevelopmentMode) {
        [self sendVariable:variable fallback:[NSNumber numberWithInteger:fallbackValue] liquidType:kLQDataTypeInteger];
    }

    NSError *error;
    LQValue *value = [_loadedLiquidPackage valueForKey:variable error:&error];
    if(error == nil) {
        if([value.variable matchesLiquidType:kLQDataTypeInteger]) {
            return [value.value integerValue];
        }
    }
    [self invalidateTargetThatIncludesVariable:variable];
    return fallbackValue;
}

- (CGFloat)floatForKey:(NSString *)variableName fallback:(CGFloat)fallbackValue {
    NSString *variable = [variableName copy];
    if(_developmentMode && self.sendFallbackValuesInDevelopmentMode) {
        [self sendVariable:variable fallback:[NSNumber numberWithFloat:fallbackValue] liquidType:kLQDataTypeFloat];
    }

    NSError *error;
    LQValue *value = [_loadedLiquidPackage valueForKey:variable error:&error];
    if(error == nil) {
        if([value.variable matchesLiquidType:kLQDataTypeFloat]) {
            return [value.value floatValue];
        }
    }
    [self invalidateTargetThatIncludesVariable:variable];
    return fallbackValue;
}

- (BOOL)boolForKey:(NSString *)variableName fallback:(BOOL)fallbackValue {
    NSString *variable = [variableName copy];
    if(_developmentMode && self.sendFallbackValuesInDevelopmentMode) {
        [self sendVariable:variable fallback:[NSNumber numberWithBool:fallbackValue] liquidType:kLQDataTypeBoolean];
    }

    NSError *error;
    LQValue *value = [_loadedLiquidPackage valueForKey:variable error:&error];
    if(error == nil) {
        if([value.variable matchesLiquidType:kLQDataTypeBoolean]) {
            return [value.value boolValue];
        }
    }
    [self invalidateTargetThatIncludesVariable:variable];
    return fallbackValue;
}

#pragma mark - Resetting

+ (void)destroySingleton {
    sharedInstance.currentUser = nil;
    sharedInstance.currentSession = nil;
    sharedInstance.enterBackgroundTime = nil;
    sharedInstance.loadedLiquidPackage = nil;
}

+ (void)softReset {
    [LQLiquidPackage destroyCachedLiquidPackageForAllTokens];
    [LQUser destroyLastUserForAllTokens];
    [Liquid destroySingleton];
    [LQDate resetUniqueNow];
    [NSThread sleepForTimeInterval:0.2f];
    LQLog(kLQLogLevelInfo, @"<Liquid> Soft reset Liquid");
}

+ (void)hardResetForApiToken:(NSString *)token {
    [self softReset];
    [LQNetworking deleteQueueForToken:token];
    LQLog(kLQLogLevelInfo, @"<Liquid> Hard reset Liquid");
}

- (void)softReset {
    [Liquid softReset];
}

- (void)hardReset {
    [Liquid hardResetForApiToken:self.apiToken];
}

@end
