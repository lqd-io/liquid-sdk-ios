//
//  Liquid.m
//  Liquid
//
//  Created by Liquid Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "Liquid.h"

#import <UIKit/UIApplication.h>
#import <AdSupport/ASIdentifierManager.h>

#import "LQEvent.h"
#import "LQSession.h"
#import "LQDevice.h"
#import "LQUser.h"
#import "LQQueue.h"
#import "LQValue.h"
#import "LQTarget.h"
#import "LQDataPoint.h"
#import "LQLiquidPackage.h"
#import "LQConstants.h"

@interface Liquid ()

@property(nonatomic, strong) NSString *apiToken;
@property(nonatomic, assign) BOOL developmentMode;
@property(nonatomic, strong) LQUser *currentUser;
@property(nonatomic, strong) LQDevice *device;
@property(nonatomic, strong) LQSession *currentSession;
@property(nonatomic, strong) NSDate *enterBackgroundTime;
@property(nonatomic, assign) BOOL inBackground;
@property(nonatomic, strong) dispatch_queue_t queue;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, strong) NSMutableArray *httpQueue;
@property(nonatomic, strong) NSDictionary *appliedValues;
@property(nonatomic, strong) LQLiquidPackage *appliedLiquidPackage; // (includes applied Targets and applied Values)

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
    if (sharedInstance == nil) LQLog(kLQLogLevelWarning, @"<Liquid> Warning: %@ sharedInstance called before sharedInstanceWithToken:", self);
    return sharedInstance;
}

#pragma mark - Instantiation

- (instancetype)initWithToken:(NSString *)apiToken {
    return [self initWithToken:apiToken development:NO];
}

- (instancetype)initWithToken:(NSString *)apiToken development:(BOOL)developemnt {
    if (apiToken == nil) apiToken = @"";
    if ([apiToken length] == 0) LQLog(kLQLogLevelWarning, @"<Liquid> Warning: %@ empty API Token", self);
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
        
        // Start auto flush timer
        [self startFlushTimer];
        if (_developmentMode && kLQSendBundleVariablesInDevelopmentMode)
            [self sendBundleVariables];

        if(!_appliedLiquidPackage) [self loadLiquidPackageSynced];

        // Bind notifications:
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(applicationDidBecomeActive:)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(applicationDidEnterBackground:)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
        
        LQLog(kLQLogLevelEvent, @"<Liquid> Initialized Liquid with API Token %@", apiToken);
    }
    return self;
}

-(BOOL)inBackground {
    if(!_inBackground) _inBackground = NO;
    return _inBackground;
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

- (void)applicationDidEnterBackground:(NSNotificationCenter *)notification {
    // Stop flush timer on app pause
    [self stopFlushTimer];
    
    // Request variables on app pause
    [self requestNewLiquidPackage];
    
    [self track:@"_pauseSession"];

    self.inBackground = [NSNumber numberWithBool:YES];
    self.enterBackgroundTime = [NSDate new];
    dispatch_async(self.queue, ^() {
        if (self.flushOnBackground) {
            [self flush];
        }
        dispatch_async(self.queue, ^() {
            // Store queue to plist
            [Liquid archiveQueue:self.httpQueue forToken:self.apiToken];
            self.httpQueue = [NSMutableArray new];
        });
    });
}

#pragma mark - User Interaction

-(void)identifyUser {
    [self identifyUserWithIdentifier:[Liquid automaticUserIdentifier]];
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
    if (!identifier || identifier.length == 0) {
        LQLog(kLQLogLevelError, @"<Liquid> Error (%@): No User identifier was given: %@", self, identifier);
        return;
    }
    dispatch_async(self.queue, ^() {
        [self destroySession];

        // Create user from identifier, attributes and location
        self.currentUser = [[LQUser alloc] initWithIdentifier:identifier
                                               withAttributes:attributes
                                                 withLocation:location];
        
        // Create session for identified user
        [self newSessionInCurrentThread:YES];
        
        // Request variables from API
        [self requestNewLiquidPackage];
        
        LQLog(kLQLogLevelEvent, @"<Liquid> From now on, we're identifying the User by the identifier '%@'", identifier);
    });
}

-(NSString *)userIdentifier {
    if(self.currentUser == nil) {
        LQLog(kLQLogLevelWarning, @"<Liquid> Warning: A user has not been identified yet. Please call [Liquid identifyUser] beforehand.");
    }
    return self.currentUser.identifier;
}

-(void)setUserAttribute:(id)attribute forKey:(NSString *)key {
    dispatch_async(self.queue, ^() {
        if(self.currentUser == nil) {
            LQLog(kLQLogLevelWarning, @"<Liquid> Warning: A user has not been identified yet. Please call [Liquid identifyUser] beforehand.");
            return;
        }
        [self.currentUser setAttribute:attribute
                                forKey:key];
    });
}

-(void)setUserLocation:(CLLocation *)location {
    dispatch_async(self.queue, ^() {
        if(self.currentUser == nil) {
            LQLog(kLQLogLevelWarning, @"<Liquid> Warning: A user has not been identified yet. Please call [Liquid identifyUser] beforehand.");
            return;
        }
        [self.currentUser setLocation:location];
    });
}

#pragma mark - Device

-(void)setDeviceAttribute:(id)attribute forKey:(NSString *)key {
    dispatch_async(self.queue, ^() {
        if(self.device == nil) {
            LQLog(kLQLogLevelWarning, @"<Liquid> Warning: A device has not been initialized. Please call [Liquid sharedInstanceWithToken:] beforehand.");
            return;
        }
        [self.device setAttribute:attribute forKey:key];
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

-(void)destroySession {
    if(self.currentUser != nil && self.currentSession != nil) {
        [[self currentSession] endSessionOnDate:self.enterBackgroundTime];
        [self track:@"_endSession"];
    }
}

-(void)newSessionInCurrentThread:(BOOL)inThread {
    __block void (^newSessionBlock)() = ^() {
        if(self.currentUser == nil) {
            LQLog(kLQLogLevelWarning, @"<Liquid> Warning: A user has not been identified yet. Please call [Liquid identifyUser] beforehand.");
            return;
        }
        self.currentSession = [[LQSession alloc] initWithTimeout:[NSNumber numberWithInt:(int)_sessionTimeout]];
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
        if(interval >= _sessionTimeout) {
            [self destroySession];
            [self newSessionInCurrentThread:NO];
            return YES;
        }
    }
    return NO;
}

-(void)setSessionAttribute:(id)attribute forKey:(NSString *)key {
    dispatch_async(self.queue, ^() {
        if(self.currentSession == nil) {
            LQLog(kLQLogLevelWarning, @"<Liquid> A session has not been initialized. Please call [Liquid identifyUser] beforehand.");
            return;
        }
        [self.currentSession setAttribute:attribute forKey:key];
    });
}

#pragma mark - Event

-(void)track:(NSString *)eventName {
    [self track:eventName withAttributes:nil];
}

-(void)track:(NSString *)eventName withAttributes:(NSDictionary *)attributes {
    LQLog(kLQLogLevelDataPoint, @"<Liquid> Tracking event %@", eventName);
    dispatch_async(self.queue, ^{
        //[Liquid assertEventAttributeTypes:attributes];
        if(self.currentUser == nil) {
            LQLog(kLQLogLevelWarning, @"<Liquid> When tracking event %@: A user has not been identified yet. Please call [Liquid identifyUser] beforehand.", eventName);
            return;
        }
        if(self.currentSession == nil) {
            LQLog(kLQLogLevelWarning, @"<Liquid> When tracking event %@: A session has not been initialized yet. Please call [Liquid identifyUser] beforehand.", eventName);
            return;
        }
        NSString *finalEventName = eventName;
        if (eventName == nil || [eventName length] == 0) {
            LQLog(kLQLogLevelWarning, @"<Liquid> Tracking unnammed event.");
            finalEventName = @"unnamedEvent";
        }
        LQEvent *event = [[LQEvent alloc] initWithName:finalEventName withAttributes:attributes];
        LQDataPoint *dataPoint = [[LQDataPoint alloc] initWithUser:self.currentUser
                                                        withDevice:self.device
                                                       withSession:self.currentSession
                                                         withEvent:event
                                                       withTargets:_appliedLiquidPackage.targets
                                                        withValues:_appliedLiquidPackage.values];
    
        NSString *endPoint = [NSString stringWithFormat:@"%@data_points", self.serverURL, nil];
        [self addToHttpQueue:[dataPoint jsonDictionary]
                withEndPoint:endPoint
              withHttpMethod:@"POST"];
    });
}

#pragma mark - Liquid Package

-(LQLiquidPackage *)requestNewLiquidPackageSynced {
    if(self.currentUser != nil && self.currentSession != nil) {
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
    } else {
        LQLog(kLQLogLevelError, @"<Liquid> A session and a user have not been initialized yet. Please call [Liquid identifyUser] beforehand.");
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
        _appliedLiquidPackage = liquidPackage;
        _appliedValues = [LQValue dictionaryFromArrayOfValues:_appliedLiquidPackage.values];
    } else {
        NSArray *emptyArray = [[NSArray alloc] initWithObjects:nil];
        _appliedLiquidPackage = [[LQLiquidPackage alloc] initWithTargets:emptyArray withValues:emptyArray];
        _appliedValues = [Liquid loadBundleValues];
    }
    
    if([self.delegate respondsToSelector:@selector(liquidDidLoadValues)]) {
        [self.delegate performSelectorOnMainThread:@selector(liquidDidLoadValues)
                                        withObject:nil
                                     waitUntilDone:NO];
    }
    LQLog(kLQLogLevelEvent, @"<Liquid> Applied Values: %@", _appliedValues);
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
            NSMutableDictionary *newVariablesDict = [[NSMutableDictionary alloc] initWithDictionary:[Liquid loadBundleValues]];
            for(NSDictionary *variableDictionary in serverVariables) {
                LQVariable *variable = [[LQVariable alloc] initFromDictionary:variableDictionary];
                [newVariablesDict removeObjectForKey:variable.name];
            }
            
            // Send new Variables to server
            for (NSString *name in newVariablesDict) {
                NSDictionary *variable = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"name",
                                          [newVariablesDict objectForKey:name], @"default_value", nil];
                LQLog(kLQLogLevelEvent, @"<Liquid> Sending bundle Variable %@", [[NSString alloc] initWithData:[Liquid toJSON:variable] encoding:NSUTF8StringEncoding]);
                BOOL res = [self sendData:[Liquid toJSON:variable]
                               toEndpoint:[NSString stringWithFormat:@"%@variables", self.serverURL]
                              usingMethod:@"POST"];
                if(!res) LQLog(kLQLogLevelError, @"<Liquid> Server did not accept data from %@", [[NSString alloc] initWithData:[Liquid toJSON:variable] encoding:NSUTF8StringEncoding]);
            }
        }
    });
}

#pragma mark - Values with Data Types

-(id)valueForVariable:(NSString *)variableName {
    if([[_appliedValues objectForKey:variableName] isKindOfClass:[NSNull class]])
        return nil;
    else
        return [_appliedValues objectForKey:variableName];
}

-(NSDate *)dateValueForVariable:(NSString *)variableName {
    if([[_appliedValues objectForKey:variableName] isKindOfClass:[NSNull class]])
        return nil;
    else if([[_appliedValues objectForKey:variableName] isKindOfClass:[NSDate class]])
        return [_appliedValues objectForKey:variableName];
    return nil;
}

-(UIColor *)colorValueForVariable:(NSString *)variableName {
    if([[_appliedValues objectForKey:variableName] isKindOfClass:[NSNull class]])
        return nil;
    @try {
        id color = [Liquid colorFromString:[_appliedValues objectForKey:variableName]];
        if([color isKindOfClass:[UIColor class]])
            return color;
        return nil;
    }
    @catch (NSException *exception) {
        LQLog(kLQLogLevelError, @"<Liquid> Variable '%@' value cannot be converted to a color: <%@> %@", variableName, exception.name, exception.reason);
        return nil;
    }
}

-(NSString *)stringValueForVariable:(NSString *)variableName {
    if([[_appliedValues objectForKey:variableName] isKindOfClass:[NSNull class]])
        return nil;
    else if([[_appliedValues objectForKey:variableName] isKindOfClass:[NSString class]])
        return [[_appliedValues objectForKey:variableName] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    return nil;
}

-(NSInteger)intValueForVariable:(NSString *)variableName {
    if([[_appliedValues objectForKey:variableName] isKindOfClass:[NSNumber class]])
        return [[_appliedValues objectForKey:variableName] integerValue];
    return 0;
}

-(CGFloat)floatValueForVariable:(NSString *)variableName {
    if([[_appliedValues objectForKey:variableName] isKindOfClass:[NSNumber class]])
        return [[_appliedValues objectForKey:variableName] floatValue];
    return 0.0f;
}

-(BOOL)boolValueForVariable:(NSString *)variableName {
    if([[_appliedValues objectForKey:variableName] isKindOfClass:[NSNumber class]])
        return [[_appliedValues objectForKey:variableName] boolValue];
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
        NSMutableArray *failedQueue = [NSMutableArray new];
        while (self.httpQueue.count > 0) {
            LQQueue *queuedHttp = [self.httpQueue firstObject];
            LQLog(kLQLogLevelEvent, @"<Liquid> Flushing %@", [queuedHttp description]);
            BOOL res = [self sendData:queuedHttp.json
                           toEndpoint:queuedHttp.url
                          usingMethod:queuedHttp.httpMethod];
            [self.httpQueue removeObject:queuedHttp];
            if(!res) {
                LQLog(kLQLogLevelError, @"<Liquid> Server did not accept data from %@", [queuedHttp description]);
                if([[queuedHttp numberOfTries] intValue]<kLQMaxNumberOfTries) {
                    [queuedHttp incrementNumberOfTries];
                    [failedQueue addObject:queuedHttp];
                }
            }
        }
        [self.httpQueue addObjectsFromArray:failedQueue];
        [Liquid archiveQueue:self.httpQueue forToken:_apiToken];
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
            LQLog(kLQLogLevelEvent, @"<Liquid> %@ started flush timer: %@", self, self.timer);
        }
    });
    
}

- (void)stopFlushTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer) {
            [self.timer invalidate];
            LQLog(kLQLogLevelEvent,@"<Liquid> %@ stopped flush timer: %@", self, self.timer);
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
    self.appliedValues = nil;
    self.appliedLiquidPackage = nil;
}

#pragma mark - Networking

- (BOOL)sendData:(NSData *)data toEndpoint:(NSString *)endpoint usingMethod:(NSString *)method {
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
    LQLog(kLQLogLevelHttp, @"<Liquid> Response from server: %@", responseString);
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if(httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        return YES;
    } else {
        return NO;
    }
}

- (NSData*)getDataFromEndpoint:(NSString *)endpoint {
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
    LQLog(kLQLogLevelHttp, @"<Liquid> Response from server: %@", responseString);
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if(httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        return responseData;
    } else {
        return nil;
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
        LQLog(kLQLogLevelError, @"<Liquid> Warning: cannot get a color from a nil value. Expected an NSString instead.");
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

+ (NSString *)automaticUserIdentifier {
    NSString *automaticUserIdentifier = nil;
    
    if (NSClassFromString(@"ASIdentifierManager")) {
        automaticUserIdentifier = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    }
    
    if (automaticUserIdentifier == nil) {
        LQLog(kLQLogLevelError, @"<Liquid> %@ error getting IFA, trying UUID", self);
        NSString *liquidUUIDKey = @"com.liquid.UUID";
        NSString *uuid = [[NSUserDefaults standardUserDefaults]objectForKey:liquidUUIDKey];
        if(uuid == nil) {
            uuid = [[NSUUID UUID] UUIDString];
            [[NSUserDefaults standardUserDefaults]setObject:uuid forKey:liquidUUIDKey];
            [[NSUserDefaults standardUserDefaults]synchronize];
        }
        automaticUserIdentifier = uuid;
    }
    if (!automaticUserIdentifier) {
        LQLog(kLQLogLevelError, @"<Liquid> %@ could not get automatic user identifier.", self);
    }
    return automaticUserIdentifier;
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

@end
