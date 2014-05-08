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
#import "LQQueue.h"
#import "LQValue.h"
#import "LQTarget.h"
#import "LQDataPoint.h"
#import "LQLiquidPackage.h"

@interface Liquid ()

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
@property(nonatomic, strong) NSDictionary *bundleFallbackValues;
@property(nonatomic, strong) LQLiquidPackage *loadedLiquidPackage; // (includes loaded Targets and loaded Values)

@end

static Liquid *sharedInstance = nil;

@implementation Liquid

@synthesize flushInterval = _flushInterval;
@synthesize autoLoadValues = _autoLoadValues;
@synthesize sessionTimeout = _sessionTimeout;

#pragma mark - Singletons

+ (Liquid *)sharedInstanceWithToken:(NSString *)apiToken {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc] initWithToken:apiToken];
    });
    return sharedInstance;
}

+ (Liquid *)sharedInstanceWithToken:(NSString *)apiToken development:(BOOL)development {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc] initWithToken:apiToken development:development];
    });
    return sharedInstance;
}

+ (Liquid *)sharedInstance {
    if (sharedInstance == nil) LQLog(kLQLogLevelError, @"<Liquid> Error: %@ sharedInstance called before sharedInstanceWithToken:", self);
    return sharedInstance;
}



#pragma mark - Initialization

- (instancetype)initWithToken:(NSString *)apiToken {
    return [self initWithToken:apiToken development:NO];
}

- (instancetype)initWithToken:(NSString *)apiToken development:(BOOL)developemnt {
    [self veryFirstMoment];
    _firstEventSent = NO;
    if (developemnt) _developmentMode = YES; else _developmentMode = NO;
    if (apiToken == nil) apiToken = @"";
    if ([apiToken length] == 0) LQLog(kLQLogLevelError, @"<Liquid> Error: %@ empty API Token", self);
    if (self = [self init]) {
        self.httpQueue = [Liquid unarchiveQueueForToken:apiToken];
        
        // Initialization
        self.apiToken = apiToken;
        self.serverURL = kLQServerUrl;
        self.flushOnBackground = kLQDefaultFlushOnBackground;
        self.device = [[LQDevice alloc] initWithLiquidVersion:kLQVersion];
        NSString *queueLabel = [NSString stringWithFormat:@"%@.%@.%p", kLQBundle, apiToken, self];
        self.queue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        _flushInterval = kLQDefaultFlushInterval.intValue;
        _sessionTimeout = kLQDefaultSessionTimeout.intValue;
        _bundleFallbackValues = [Liquid loadBundleValues];
        
        // Start auto flush timer
        [self startFlushTimer];
        if (_developmentMode && kLQSendBundleVariablesInDevelopmentMode)
            [self sendBundleVariables];

        if(!_loadedLiquidPackage) [self loadLiquidPackageSynced];

        // Bind notifications:
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(applicationDidBecomeActive:)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(applicationWillResignActive:)
                                   name:UIApplicationWillResignActiveNotification
                                 object:nil];
        
        LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Initialized Liquid with API Token %@", apiToken);
    }
    return self;
}

#pragma mark - Lazy initialization

- (BOOL)inBackground {
    if (!_inBackground) _inBackground = NO;
    return _inBackground;
}

- (NSDate *)veryFirstMoment {
    if (!_veryFirstMoment) _veryFirstMoment = [NSDate new];
    return _veryFirstMoment;
}

#pragma mark - UIApplication notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    // Check for session timeout on app resume
    BOOL sessionTimedOut = [self checkSessionTimeout];
    
    // Restart flush timer
    [self startFlushTimer];
    
    // Request variables on app resume
    [self loadLiquidPackageSynced];
    dispatch_async(self.queue, ^() {
        self.enterBackgroundTime = nil;
        // Restore queue from plist
        self.httpQueue = [Liquid unarchiveQueueForToken:self.apiToken];
    });

    if(!sessionTimedOut && self.inBackground) {
        [self track:@"_resumeSession"];
        _inBackground = NO;
    }
}

- (void)applicationWillResignActive:(NSNotificationCenter *)notification {
    self.enterBackgroundTime = [NSDate new];
    self.inBackground = YES;

    // Stop flush timer on app pause
    [self stopFlushTimer];
    
    [self track:@"_pauseSession"];

    // Store queue to plist
    [Liquid archiveQueue:self.httpQueue forToken:self.apiToken];
    self.httpQueue = [NSMutableArray new];

    if (self.flushOnBackground) {
        [self flush];
    }

    // Request variables on app pause
    [self requestNewLiquidPackageSynced];
}

#pragma mark - User Interaction

-(void)identifyUser {
    [self identifyUserWithIdentifier:nil];
}

-(void)identifyUserWithIdentifier:(NSString *)identifier {
    [self identifyUserWithIdentifier:identifier
                      withAttributes:nil];
}

-(void)identifyUserWithIdentifier:(NSString *)identifier withAttributes:(NSDictionary *)attributes {
    [self identifyUserWithIdentifier:identifier
                      withAttributes:attributes
                        withLocation:nil];
}

-(void)identifyUserWithIdentifier:(NSString *)identifier withAttributes:(NSDictionary *)attributes withLocation:(CLLocation *)location {
    if (identifier && identifier.length == 0) {
        LQLog(kLQLogLevelError, @"<Liquid> Error (%@): No User identifier was given: %@", self, identifier);
        return;
    }
    dispatch_async(self.queue, ^() {
        [self identifyUserSyncedWithIdentifier:identifier withAttributes:attributes withLocation:location];
    });
}

-(void)identifyUserSyncedWithIdentifier:(NSString *)identifier withAttributes:(NSDictionary *)attributes withLocation:(CLLocation *)location {
    [self destroySessionIfExists];

    // Create user from identifier, attributes and location
    self.currentUser = [[LQUser alloc] initWithIdentifier:identifier
                                           withAttributes:attributes
                                             withLocation:location];

    // Create session for identified user
    [self newSessionInCurrentThread:YES];

    // Request variables from API
    [self requestNewLiquidPackage];

    LQLog(kLQLogLevelInfoVerbose, @"<Liquid> From now on, we're identifying the User by identifier '%@'", self.currentUser.identifier);
}

-(NSString *)userIdentifier {
    if(self.currentUser == nil) {
        LQLog(kLQLogLevelError, @"<Liquid> Error: A user has not been identified yet. Please call [Liquid identifyUser] beforehand.");
    }
    return self.currentUser.identifier;
}

-(void)setUserAttribute:(id)attribute forKey:(NSString *)key {
    dispatch_async(self.queue, ^() {
        if(self.currentUser == nil) {
            LQLog(kLQLogLevelError, @"<Liquid> Error: A user has not been identified yet. Please call [Liquid identifyUser] beforehand.");
            return;
        }
        [self.currentUser setAttribute:attribute
                                forKey:key];
    });
}

-(void)setUserLocation:(CLLocation *)location {
    dispatch_async(self.queue, ^() {
        if(self.currentUser == nil) {
            LQLog(kLQLogLevelError, @"<Liquid> Error: A user has not been identified yet. Please call [Liquid identifyUser] beforehand.");
            return;
        }
        [self.currentUser setLocation:location];
    });
}

#pragma mark - Session

- (NSInteger)sessionTimeout {
    @synchronized(self) {
        return _sessionTimeout;
    }
}

- (void)setSessionTimeout:(NSInteger)sessionTimeout {
    @synchronized(self) {
        _sessionTimeout = sessionTimeout;
    }
}

-(void)destroySessionIfExists {
    if(self.currentUser != nil && self.currentSession != nil) {
        [[self currentSession] endSessionOnDate:self.enterBackgroundTime];
        [self track:@"_endSession"];
    }
}

-(void)newSessionInCurrentThread:(BOOL)inThread {
    NSDate *now = [NSDate new];
    __block void (^newSessionBlock)() = ^() {
        if(self.currentUser == nil) {
            LQLog(kLQLogLevelError, @"<Liquid> Error: A user has not been identified yet. Please call [Liquid identifyUser] beforehand.");
            return;
        }
        self.currentSession = [[LQSession alloc] initWithDate:now withTimeout:[NSNumber numberWithInt:(int)_sessionTimeout]];
        [self track:@"_startSession"];
    };
    if(inThread)
        newSessionBlock();
    else
        dispatch_async(self.queue, newSessionBlock);
}

-(BOOL)checkSessionTimeout {
    if(self.currentSession != nil) {
        NSDate *now = [NSDate new];
        NSTimeInterval interval = [now timeIntervalSinceDate:self.enterBackgroundTime];
        if(interval >= _sessionTimeout || interval > [kLQDefaultSessionMaxLimit intValue]) {
            [self destroySessionIfExists];
            [self newSessionInCurrentThread:NO];
            return YES;
        }
    }
    return NO;
}

#pragma mark - Event

-(void)track:(NSString *)eventName {
    [self track:eventName withAttributes:nil];
}

-(void)track:(NSString *)eventName withAttributes:(NSDictionary *)attributes {
    if(self.currentUser == nil) {
        [self identifyUserSyncedWithIdentifier:nil
                                withAttributes:nil
                                  withLocation:nil];
        LQLog(kLQLogLevelInfo, @"<Liquid> Auto identifying user (%@)", self.currentUser.identifier);
    }

    NSDate *now;
    if (!_firstEventSent) {
        now = [self veryFirstMoment];
        _firstEventSent = YES;
    } else {
        now = [NSDate new];
    }

    if ([eventName hasPrefix:@"_"]) {
        LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Tracking Liquid event %@ (%@)", eventName, [[Liquid isoDateFormatter] stringFromDate:now]);
    } else {
        LQLog(kLQLogLevelInfo, @"<Liquid> Tracking event %@ (%@)", eventName, [[Liquid isoDateFormatter] stringFromDate:now]);
    }
    dispatch_async(self.queue, ^{
        //[Liquid assertEventAttributeTypes:attributes];
        NSString *finalEventName = eventName;
        if (eventName == nil || [eventName length] == 0) {
            LQLog(kLQLogLevelInfo, @"<Liquid> Tracking unnammed event.");
            finalEventName = @"unnamedEvent";
        }
        LQEvent *event = [[LQEvent alloc] initWithName:finalEventName withAttributes:attributes withDate:now];
        LQDataPoint *dataPoint = [[LQDataPoint alloc] initWithDate:now
                                                          withUser:self.currentUser
                                                        withDevice:self.device
                                                       withSession:self.currentSession
                                                         withEvent:event
                                                       withTargets:_loadedLiquidPackage.targets
                                                        withValues:_loadedLiquidPackage.values];
    
        NSString *endPoint = [NSString stringWithFormat:@"%@data_points", self.serverURL, nil];
        [self addToHttpQueue:[dataPoint jsonDictionary]
                withEndPoint:endPoint
              withHttpMethod:@"POST"];
    });
}

#pragma mark - Liquid Package

-(LQLiquidPackage *)requestNewLiquidPackageSynced {
    if(self.currentUser == nil || self.currentSession == nil) {
        [self identifyUserSyncedWithIdentifier:nil
                                withAttributes:nil
                                  withLocation:nil];
        LQLog(kLQLogLevelInfo, @"<Liquid> Auto identifying user (%@)", self.currentUser.identifier);
    } else {
        NSString *endPoint = [NSString stringWithFormat:@"%@users/%@/devices/%@/liquid_package", self.serverURL, self.currentUser.identifier, self.device.uid, nil];
        NSData *dataFromServer = [self getDataFromEndpoint:endPoint];
        LQLiquidPackage *liquidPacakge = nil;
        if(dataFromServer != nil) {
            NSDictionary *liquidPackageDictionary = [Liquid fromJSON:dataFromServer];
            if(liquidPackageDictionary == nil) {
                return nil;
            }
            liquidPacakge = [[LQLiquidPackage alloc] initFromDictionary:liquidPackageDictionary];
            [liquidPacakge saveToDisk];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:LQDidReceiveValues object:nil];
            if([self.delegate respondsToSelector:@selector(liquidDidReceiveValues)]) {
                [self.delegate performSelectorOnMainThread:@selector(liquidDidReceiveValues)
                                                withObject:nil
                                             waitUntilDone:NO];
            }
            if(_autoLoadValues) {
                [self loadLiquidPackage];
            }
        }
        return liquidPacakge;
    }
    return nil;
}

-(void)requestNewLiquidPackage {
    dispatch_async(self.queue, ^{
        [self requestNewLiquidPackageSynced];
    });
}

-(void)requestNewValues {
    [self requestNewLiquidPackage];
}

-(void)loadLiquidPackageSynced {
    LQLiquidPackage *liquidPackage = [LQLiquidPackage loadFromDisk];
    if (liquidPackage) {
        _loadedLiquidPackage = liquidPackage;
    } else {
        NSArray *emptyArray = [[NSArray alloc] initWithObjects:nil];
        _loadedLiquidPackage = [[LQLiquidPackage alloc] initWithTargets:emptyArray withValues:emptyArray];
    }
    
    NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:[_loadedLiquidPackage dictOfVariablesAndValues], @"values", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:LQDidLoadValues object:nil userInfo:userInfo];
    if([self.delegate respondsToSelector:@selector(liquidDidLoadValues)]) {
        [self.delegate performSelectorOnMainThread:@selector(liquidDidLoadValues)
                                        withObject:nil
                                     waitUntilDone:NO];
    }
    LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Loaded Values: %@", [_loadedLiquidPackage dictOfVariablesAndValues]);
}

-(void)loadLiquidPackage {
    dispatch_async(self.queue, ^{
        [self loadLiquidPackageSynced];
    });
}

-(void)loadNewValues {
    [self loadLiquidPackage];
}

-(void)sendBundleVariables {
    dispatch_async(self.queue, ^{
        // Get list of variables that are already on the server
        NSData *dataFromServer = [self getDataFromEndpoint:[NSString stringWithFormat:@"%@variables", self.serverURL, nil]];
        NSArray *serverVariables = [[NSArray alloc] initWithObjects:nil];
        if(dataFromServer != nil) {
            serverVariables = [Liquid fromJSON:dataFromServer];
        
            // Build the list of Variables to create on server (only the Bundle Variables that are not on the server yet)
            NSMutableDictionary *newVariablesDict = [[NSMutableDictionary alloc] initWithDictionary:_bundleFallbackValues];
            for(NSDictionary *variableDictionary in serverVariables) {
                LQVariable *variable = [[LQVariable alloc] initFromDictionary:variableDictionary];
                [newVariablesDict removeObjectForKey:variable.name];
            }
            
            // Send new Variables to server
            for (NSString *name in newVariablesDict) {
                NSDictionary *variable = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"name",
                                          [newVariablesDict objectForKey:name], @"default_value", nil];
                LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Sending bundle Variable %@", [[NSString alloc] initWithData:[Liquid toJSON:variable] encoding:NSUTF8StringEncoding]);
                NSInteger res = [self sendData:[Liquid toJSON:variable]
                               toEndpoint:[NSString stringWithFormat:@"%@variables", self.serverURL]
                              usingMethod:@"POST"];
                if(res != LQQueueStatusOk) LQLog(kLQLogLevelHttp, @"<Liquid> Could not send variables to server %@", [[NSString alloc] initWithData:[Liquid toJSON:variable] encoding:NSUTF8StringEncoding]);
            }
        }
    });
}

#pragma mark - Values with Data Types

-(id)bundleValueForVariable:(NSString *)variableName {
    return [_bundleFallbackValues objectForKey:variableName];
}

-(NSDate *)dateForKey:(NSString *)variableName fallback:(NSDate *)fallbackValue {
    id value = [_loadedLiquidPackage valueForKey:variableName fallback:fallbackValue];
    if([value isKindOfClass:[NSDate class]])
        return value;
    return nil;
}

-(NSDate *)dateForKey:(NSString *)variableName {
    return [self dateForKey:variableName fallback:[self bundleValueForVariable:variableName]];
}

-(UIColor *)colorForKey:(NSString *)variableName fallback:(UIColor *)fallbackValue {
    id value = [_loadedLiquidPackage valueForKey:variableName fallback:fallbackValue];
    @try {
        id color = [Liquid colorFromString:value];
        if([color isKindOfClass:[UIColor class]])
            return color;
        return nil;
    }
    @catch (NSException *exception) {
        LQLog(kLQLogLevelError, @"<Liquid> Variable '%@' value cannot be converted to a color: <%@> %@", variableName, exception.name, exception.reason);
        return nil;
    }
}

-(UIColor *)colorForKey:(NSString *)variableName {
    return [self colorForKey:variableName fallback:[Liquid colorFromString:[self bundleValueForVariable:variableName]]];
}

-(NSString *)stringForKey:(NSString *)variableName fallback:(NSString *)fallbackValue {
    id value = [_loadedLiquidPackage valueForKey:variableName fallback:fallbackValue];
    if([value isKindOfClass:[NSString class]])
        return [value stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    return nil;
}

-(NSString *)stringForKey:(NSString *)variableName {
    return [self stringForKey:variableName fallback:[self bundleValueForVariable:variableName]];
}

-(NSNumber *)numberForKey:(NSString *)variableName fallback:(NSNumber *)fallbackValue {
    id value = [_loadedLiquidPackage valueForKey:variableName fallback:fallbackValue];
    if([value isKindOfClass:[NSNumber class]])
        return value;
    return nil;
}

-(NSNumber *)numberForKey:(NSString *)variableName {
    return [self numberForKey:variableName fallback:[self bundleValueForVariable:variableName]];
}

-(NSInteger)intForKey:(NSString *)variableName fallback:(NSInteger)fallbackValue {
    id value = [_loadedLiquidPackage valueForKey:variableName fallback:nil];
    if([value isKindOfClass:[NSNumber class]])
        return [value integerValue];
    return fallbackValue;
}

-(NSInteger)intForKey:(NSString *)variableName {
    id bundleValue = [self bundleValueForVariable:variableName];
    if([bundleValue isKindOfClass:[NSNumber class]]) {
        return [self intForKey:variableName fallback:[bundleValue intValue]];
    }
    else return 0;
}

-(CGFloat)floatForKey:(NSString *)variableName fallback:(CGFloat)fallbackValue {
    id value = [_loadedLiquidPackage valueForKey:variableName fallback:nil];
    if([value isKindOfClass:[NSNumber class]])
        return [value floatValue];
    return fallbackValue;
}

-(CGFloat)floatForKey:(NSString *)variableName {
    id bundleValue = [self bundleValueForVariable:variableName];
    if([[bundleValue objectForKey:variableName] isKindOfClass:[NSNumber class]]) {
        return [self floatForKey:variableName fallback:[bundleValue floatValue]];
    }
    return 0.0f;
}

-(BOOL)boolForKey:(NSString *)variableName fallback:(BOOL)fallbackValue {
    id value = [_loadedLiquidPackage valueForKey:variableName fallback:nil];
    if([value isKindOfClass:[NSNumber class]])
        return [value boolValue];
    return fallbackValue;
}

-(BOOL)boolForKey:(NSString *)variableName {
    id bundleValue = [self bundleValueForVariable:variableName];
    if ([bundleValue isKindOfClass:[NSNumber class]]) {
        return [self boolForKey:variableName fallback:[bundleValue boolValue]];
    }
    return NO;
}

#pragma mark - Queueing

-(void)addToHttpQueue:(NSDictionary*)dictionary withEndPoint:(NSString*)endPoint withHttpMethod:(NSString*)httpMethod {
    NSData *json = [Liquid toJSON:dictionary];
    LQQueue *queuedEvent = [[LQQueue alloc] initWithUrl:endPoint
                                         withHttpMethod:httpMethod
                                               withJSON:json];

    if (self.httpQueue.count < kLQQueueSizeLimit) {
        [self.httpQueue addObject:queuedEvent];
        [Liquid archiveQueue:self.httpQueue
                    forToken:self.apiToken];
    } else {
        LQLog(kLQLogLevelWarning, @"<Liquid> Queue excdeeded its limit size (%d).", kLQQueueSizeLimit);
    }
}

-(void)flush {
    dispatch_async(self.queue, ^{
        if (![self.device reachesInternet]) {
            LQLog(kLQLogLevelWarning, @"<Liquid> There's no Internet connection. Will try to deliver data points later.");
        } else {
            NSMutableArray *failedQueue = [NSMutableArray new];
            while (self.httpQueue.count > 0) {
                LQQueue *queuedHttp = [self.httpQueue firstObject];
                if ([[NSDate date] compare:[queuedHttp nextTryAfter]] > NSOrderedAscending) {
                    LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Flushing %@", [queuedHttp description]);
                    NSInteger res = [self sendData:queuedHttp.json
                                   toEndpoint:queuedHttp.url
                                  usingMethod:queuedHttp.httpMethod];
                    [self.httpQueue removeObject:queuedHttp];
                    if(res != LQQueueStatusOk) {
                        if([[queuedHttp numberOfTries] intValue] < kLQHttpMaxTries) {
                            if (res == LQQueueStatusUnauthorized) {
                                [queuedHttp incrementNumberOfTries];
                                [queuedHttp incrementNextTryDateIn:kLQHttpUnreachableWait];
                            }
                            if (res == LQQueueStatusRejected) {
                                [queuedHttp incrementNumberOfTries];
                                [queuedHttp incrementNextTryDateIn:kLQHttpRejectedWait];
                            }
                            [failedQueue addObject:queuedHttp];
                        }
                    }
                } else {
                    [self.httpQueue removeObject:queuedHttp];
                    [failedQueue addObject:queuedHttp];
                    LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Queued failed request is too recent. Waiting for a while to try again (%d/%d)", [[queuedHttp numberOfTries] intValue], kLQHttpMaxTries);
                }
            }
            [self.httpQueue addObjectsFromArray:failedQueue];
            [Liquid archiveQueue:self.httpQueue forToken:_apiToken];
        }
    });
}

- (NSUInteger)flushInterval {
    @synchronized(self) {
        return _flushInterval;
    }
}

- (void)setFlushInterval:(NSUInteger)interval {
    [self stopFlushTimer];
    @synchronized(self) {
        _flushInterval = interval;
    }
    [self startFlushTimer];
}

- (void)startFlushTimer {
    //[self stopFlushTimer];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.flushInterval > 0 && self.timer == nil) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:self.flushInterval
                                                          target:self
                                                        selector:@selector(flush)
                                                        userInfo:nil
                                                         repeats:YES];
            LQLog(kLQLogLevelInfoVerbose, @"<Liquid> %@ started flush timer: %@", self, self.timer);
        }
    });
    
}

- (void)stopFlushTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer) {
            [self.timer invalidate];
            LQLog(kLQLogLevelInfoVerbose,@"<Liquid> %@ stopped flush timer: %@", self, self.timer);
        }
        self.timer = nil;
    });
}

#pragma mark - Resetting

- (void)reset {
    self.currentUser = nil;
    self.device = nil;
    self.currentSession = nil;
    self.apiToken = nil;
    self.enterBackgroundTime = nil;
    self.enterBackgroundTime = nil;
    self.timer = nil;
    self.httpQueue = nil;
    self.loadedLiquidPackage = nil;
}

#pragma mark - Networking

- (NSInteger)sendData:(NSData *)data toEndpoint:(NSString *)endpoint usingMethod:(NSString *)method {
    NSURL *url = [NSURL URLWithString:endpoint];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];
    [request setValue:[NSString stringWithFormat:@"Token %@", self.apiToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:[NSString stringWithFormat:@"Liquid/%@", kLQVersion] forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/vnd.lqd.v1+json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[data length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];

    NSURLResponse *response;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&error];
    NSString *responseString = [[NSString alloc] initWithData:responseData
                                                     encoding:NSUTF8StringEncoding];

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (error) {
        if (error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorCannotConnectToHost || error.code == NSURLErrorNetworkConnectionLost) {
            LQLog(kLQLogLevelWarning, @"<Liquid> Error (%d) while sending data to server: Server is unreachable", error.code);
            return LQQueueStatusUnreachable;
        } else if(error.code == NSURLErrorUserCancelledAuthentication || error.code == NSURLErrorUserAuthenticationRequired) {
            LQLog(kLQLogLevelError, @"<Liquid> Error (%d) while sending data to server: Unauthorized (check App Token)", error.code);
            return LQQueueStatusUnauthorized;
        } else {
            LQLog(kLQLogLevelWarning, @"<Liquid> Error (%d) while sending data to server: Server error", error.code);
            return LQQueueStatusRejected;
        }
    } else {
        LQLog(kLQLogLevelHttp, @"<Liquid> Response from server: %@", responseString);
        if(httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
            return LQQueueStatusOk;
        } else {
            LQLog(kLQLogLevelWarning, @"<Liquid> Error (%d) while sending data to server: Server error", httpResponse.statusCode);
            return LQQueueStatusRejected;
        }
    }
}

- (NSData *)getDataFromEndpoint:(NSString *)endpoint {
    NSURL *url = [NSURL URLWithString:endpoint];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:[NSString stringWithFormat:@"Token %@", self.apiToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:[NSString stringWithFormat:@"Liquid/%@", kLQVersion] forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/vnd.lqd.v1+json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    NSURLResponse *response;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&error];
    NSString *responseString = [[NSString alloc] initWithData:responseData
                                                     encoding:NSUTF8StringEncoding];

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (error) {
        if (error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorCannotConnectToHost || error.code == NSURLErrorNetworkConnectionLost) {
            LQLog(kLQLogLevelWarning, @"<Liquid> Error (%d) while getting data from server: Server is unreachable", error.code);
        } else if(error.code == NSURLErrorUserCancelledAuthentication || error.code == NSURLErrorUserAuthenticationRequired) {
            LQLog(kLQLogLevelError, @"<Liquid> Error (%d) while getting data from server: Unauthorized (check App Token)", error.code);
        } else {
            LQLog(kLQLogLevelWarning, @"<Liquid> Error (%d) while getting data from server: Server error", error.code);
        }
        return nil;
    } else {
        LQLog(kLQLogLevelHttp, @"<Liquid> Response from server: %@", responseString);
        if(httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
            return responseData;
        } else {
            LQLog(kLQLogLevelWarning, @"<Liquid> Error (%d) while getting data from server: Server error", httpResponse.statusCode);
            return nil;
        }
    }
}

#pragma mark - File Management

+(NSMutableArray*)unarchiveQueueForToken:(NSString*)apiToken {
    NSMutableArray *plistArray =  [NSKeyedUnarchiver unarchiveObjectWithFile:[Liquid liquidQueueFileForToken:apiToken]];
    if(plistArray == nil)
        plistArray = [NSMutableArray new];
    LQLog(kLQLogLevelData, @"<Liquid> Loading queue with %ld items from disk", (unsigned long)plistArray.count);
    return plistArray;
}

+(BOOL)archiveQueue:(NSMutableArray*)queue forToken:(NSString*)apiToken {
    if (queue.count > 0) {
        LQLog(kLQLogLevelData, @"<Liquid> Saving queue with %ld items to disk", (unsigned long)queue.count);
        return [NSKeyedArchiver archiveRootObject:queue
                                           toFile:[Liquid liquidQueueFileForToken:apiToken]];
    } else {
        [Liquid deleteFileIfExists:[Liquid liquidQueueFileForToken:apiToken] error:nil];
        return FALSE;
    }
}

+(BOOL)deleteFileIfExists:(NSString *)fileName error:(NSError **)err {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exists = [fm fileExistsAtPath:fileName];
    if (exists == YES) return [fm removeItemAtPath:fileName error:err];
    return exists;
}

+(NSString*)liquidQueueFileForToken:(NSString*)apiToken {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *liquidDirectory = [documentsDirectory stringByAppendingPathComponent:kLQDirectory];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:liquidDirectory])
        [[NSFileManager defaultManager] createDirectoryAtPath:liquidDirectory
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:&error];
    
    NSString *liquidFile = [liquidDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.queue", apiToken]];
    LQLog(kLQLogLevelPaths,@"<Liquid> File location %@", liquidFile);
    return liquidFile;
}

+(NSDictionary*)loadBundleValues {
    NSString *variablesPlistPath = [[NSBundle mainBundle] pathForResource:kLQValuesFileName ofType:@"plist"];
    NSDictionary *values = [[NSDictionary alloc] initWithContentsOfFile:variablesPlistPath];
    return values;
}

#pragma mark - Static Helpers

+ (void)assertEventAttributeTypes:(NSDictionary *)properties {
    for (id k in properties) {
        NSAssert([k isKindOfClass: [NSString class]], @"%@ property keys must be NSString. got: %@ %@", self, [k class], k);
        // would be convenient to do: id v = [properties objectForKey:k]; but
        // when the NSAssert's are stripped out in release, it becomes an
        // unused variable error. also, note that @YES and @NO pass as
        // instances of NSNumber class.
        NSAssert([[properties objectForKey:k] isKindOfClass:[NSString class]] ||
                 [[properties objectForKey:k] isKindOfClass:[NSNumber class]] ||
                 [[properties objectForKey:k] isKindOfClass:[NSNull class]] ||
                 [[properties objectForKey:k] isKindOfClass:[NSDate class]],
                 @"%@ property values must be NSString, NSNumber or NSDate. got: %@ %@", self, [[properties objectForKey:k] class], [properties objectForKey:k]);
    }
}

+ (UIColor *)colorFromString:(NSString *)hexString {
    if (![hexString isKindOfClass:[NSString class]]) {
        LQLog(kLQLogLevelWarning, @"<Liquid> Warning: cannot get a color from a nil value. Expected an NSString instead.");
        return nil;
    }
    if([hexString rangeOfString:@"#"].location != 0)
        return nil;
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if([cleanString length] == 3) {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                       [cleanString substringWithRange:NSMakeRange(0, 1)], [cleanString substringWithRange:NSMakeRange(0, 1)],
                       [cleanString substringWithRange:NSMakeRange(1, 1)], [cleanString substringWithRange:NSMakeRange(1, 1)],
                       [cleanString substringWithRange:NSMakeRange(2, 1)], [cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    if([cleanString length] == 6) {
        cleanString = [cleanString stringByAppendingString:@"ff"];
    }
    
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    float red = ((baseValue >> 24) & 0xFF)/255.0f;
    float green = ((baseValue >> 16) & 0xFF)/255.0f;
    float blue = ((baseValue >> 8) & 0xFF)/255.0f;
    float alpha = ((baseValue >> 0) & 0xFF)/255.0f;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (NSString *)hexStringFromUIColor:(UIColor *)color {
    if (![color isKindOfClass:[UIColor class]]) {
        LQLog(kLQLogLevelWarning, @"<Liquid> Warning: cannot get a hex color value from a nil value. Expected an UIColor instead.");
        return nil;
    }
    if (CGColorGetNumberOfComponents(color.CGColor) < 4) {
        const CGFloat *components = CGColorGetComponents(color.CGColor);
        color = [UIColor colorWithRed:components[0] green:components[0] blue:components[0] alpha:components[1]];
    }
    if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) != kCGColorSpaceModelRGB) {
        return [NSString stringWithFormat:@"#FFFFFF"];
    }
    return [NSString stringWithFormat:@"#%02X%02X%02X", (int)((CGColorGetComponents(color.CGColor))[0]*255.0), (int)((CGColorGetComponents(color.CGColor))[1]*255.0), (int)((CGColorGetComponents(color.CGColor))[2]*255.0)];
}

+ (id)fromJSON:(NSData *)data {
    if (!data) return nil;
    __autoreleasing NSError *error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions
                                                  error:&error];
    if (error != nil) {
        LQLog(kLQLogLevelError, @"<Liquid> Error parsing JSON: %@", [error localizedDescription]);
        return nil;
    }
    return result;
}

+ (NSData*)toJSON:(id)object {
    __autoreleasing NSError *error = nil;
    NSData *data = object;
    id result = [NSJSONSerialization dataWithJSONObject:data
                                                options:NSJSONWritingPrettyPrinted
                                                  error:&error];
    if (error != nil) {
        LQLog(kLQLogLevelError, @"<Liquid> Error creating JSON: %@", [error localizedDescription]);
        return nil;
    }
    return result;
}

+ (NSData *)randomDataOfLength:(size_t)length {
    NSMutableData *data = [NSMutableData dataWithLength:length];
    SecRandomCopyBytes(kSecRandomDefault, length, data.mutableBytes);
    return data;
}

+ (NSString *)generateRandomUniqueId {
    NSData *data = [Liquid randomDataOfLength:16];
    NSString *dataStrWithoutBrackets = [[NSString stringWithFormat:@"%@", data]
                                        stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    NSString *dataStr = [dataStrWithoutBrackets stringByReplacingOccurrencesOfString:@" "
                                                                          withString:@""];
    return dataStr;
}

+(NSDateFormatter *)isoDateFormatter {
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZ"];
    [formatter setCalendar:gregorianCalendar];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    return formatter;
}

@end
