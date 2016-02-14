//
//  LQUIElementChanger.m
//  Liquid
//
//  Created by Miguel M. Almeida on 10/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQDefaults.h"
#import "LQUIElementChanger.h"
#import <objc/runtime.h>
#import <Aspects/Aspects.h>
#import <UIKit/UIKit.h>
#import "UIView+LQChangeable.h"
#import "NSData+LQData.h"
#import "LQStorage.h"

@interface LQUIElementChanger ()

@property (nonatomic, strong) NSDictionary<NSString *, LQUIElement *> *changedElements;
@property (nonatomic, strong) LQNetworking *networking;
@property (nonatomic, strong) NSString *appToken;

@end

@implementation LQUIElementChanger

@synthesize changedElements = _changedElements;
@synthesize networking = _networking;
@synthesize developerToken = _developerToken;
@synthesize appToken = _appToken;

#pragma mark - Initializers

- (instancetype)initWithNetworking:(LQNetworking *)networking appToken:(NSString *)appToken {
    self = [super init];
    if (self) {
        self.networking = networking;
        self.appToken = appToken;
    }
    return self;
}

- (void)interceptUIElementsWithBlock:(void(^)(UIView *view))interceptBlock {
    static dispatch_once_t onceToken; // TODO: probably get rid of this
    dispatch_once(&onceToken, ^{
        [UIControl aspect_hookSelector:@selector(didMoveToWindow) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo) {
            id view = [aspectInfo instance];
            if ([view isKindOfClass:[UIView class]]) {
                interceptBlock(view);
            }
        } error:NULL];
    });
}

#pragma mark - Change Elements

- (BOOL)applyChangesTo:(UIView *)view {
    LQUIElement *uiElement = [self uiElementFor:view];
    if (!uiElement || ![view isChangeable]) {
        return false;
    }
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        [button addTarget:self action:@selector(touchUpButton:) forControlEvents:UIControlEventTouchUpInside];
        LQLog(kLQLogLevelInfo, @"<Liquid/UIElementChanger>Tracking events in UIButton with identifier \"%@\" and label \"%@\"", [uiElement identifier], button.titleLabel.text);
        return true;
    }
    return false;
}

- (void)touchUpButton:(UIButton *)button {
    LQUIElement *uiElement = [self uiElementFor:button];
    if (![uiElement eventName]) {
        return;
    }
    LQLog(kLQLogLevelInfo, @"<Liquid/UIElementChanger>Touched button %@ with identifier %@ to track event named %@",
          button.titleLabel.text, button.liquidIdentifier, uiElement.eventName);
}

#pragma mark - Request and Register UI Elements from/on server

- (void)requestUiElements {
    [_networking getDataFromEndpoint:@"ui_elements" withParameters:[self requestParamsWith:@{ @"platform" : @"ios" }]
                   completionHandler:^(LQQueueStatus queueStatus, NSData *responseData) {
        if (queueStatus == LQQueueStatusOk) {
            NSMutableDictionary *newElements = [[NSMutableDictionary alloc] init];
            for (NSDictionary *uiElementDict in [NSData fromJSON:responseData]) {
                LQUIElement *uiElement = [[LQUIElement alloc] initFromDictionary:uiElementDict];
                [newElements setObject:uiElement forKey:uiElement.identifier];
            }
            self.changedElements = newElements;
            LQLog(kLQLogLevelInfo, @"<Liquid/UIElementChanger> Received %ld UI Elements from server", (unsigned long) newElements.count);
            [self archiveUIElements]; // TODO: only archive if they are different (with an md5)?
            [self logChangedElements];
        } else {
            LQLog(kLQLogLevelHttpError, @"<Liquid/UIElementChanger> Error requesting UI Elements: %@", responseData);
        }
    }];
}

- (void)addUIElement:(LQUIElement *)element {
    NSMutableDictionary *newElements = [NSMutableDictionary dictionaryWithDictionary:self.changedElements];
    [newElements setObject:element forKey:element.identifier];
    self.changedElements = newElements;
    [self logChangedElements];
}

- (void)removeUIElement:(LQUIElement *)element {
    NSMutableDictionary *newElements = [NSMutableDictionary dictionaryWithDictionary:self.changedElements];
    [newElements removeObjectForKey:element.identifier];
    self.changedElements = newElements;
    [self logChangedElements];
}

#pragma mark - Helper methods

- (BOOL)viewIsTrackingEvent:(UIView *)view {
    LQUIElement *element = [self uiElementFor:view];
    return element && element.eventName;
}

- (LQUIElement *)uiElementFor:(UIView *)view {
    LQUIElement *element = [self.changedElements objectForKey:[view liquidIdentifier]];
    if (element) {
        return element;
    }
    return nil;
}

- (NSDictionary *)requestParams {
    return [self requestParamsWith:nil];
}

- (NSDictionary *)requestParamsWith:(NSDictionary *)params {
    if (!self.developerToken) {
        return params;
    }
    NSMutableDictionary *queryParams = [[NSMutableDictionary alloc] initWithDictionary:params];
    queryParams[@"token"] = self.developerToken;
    return queryParams;
}

- (void)logChangedElements {
    if (kLQLogLevel < kLQLogLevelInfoVerbose) return;
    LQLog(kLQLogLevelInfoVerbose, @"<Liquid/UIElementChanger> List of Changed UI Elements:");
    for (NSString *identifier in self.changedElements) {
        LQLog(kLQLogLevelInfoVerbose, @"* %@", identifier);
    }
}

#pragma mark - Save and Restore to/from Disk

- (BOOL)archiveUIElements {
    LQLog(kLQLogLevelInfo, @"<Liquid/UIElementChanger> Saving %ld UI Elements to disk", (unsigned long) self.changedElements.count);
    return [NSKeyedArchiver archiveRootObject:self.changedElements toFile:[[self class] uiElementsFilePathForToken:self.appToken]];
}

- (void)unarchiveUIElements {
    self.changedElements = [[self class] unarchiveUIElementsForToken:self.appToken];
    LQLog(kLQLogLevelInfo, @"<Liquid/UIElementChanger> Unarchavied %ld UI Elements from disk", (unsigned long) self.changedElements.count);
    return;
}

+ (NSDictionary<NSString *, LQUIElement *> *)unarchiveUIElementsForToken:(NSString *)apiToken {
    NSString *filePath = [[self class] uiElementsFilePathForToken:apiToken];
    NSDictionary<NSString *, LQUIElement *> *uiElements = nil;
    @try {
        id object = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        uiElements = [object isKindOfClass:[NSDictionary class]] ? object : nil;
    }
    @catch (NSException *exception) {
        LQLog(kLQLogLevelError, @"<Liquid/UIElementChanger> %@: Found invalid UI Elements in cache. Destroying it...", [exception name]);
        [LQStorage deleteFileIfExists:filePath error:nil];
    }
    if (uiElements && [uiElements count] > 0) {
        LQLog(kLQLogLevelData, @"<Liquid/UIElementChanger> Loaded %ld UI Elements from disk.", (unsigned long) uiElements.count);
    }
    return uiElements;
}

+ (NSString*)uiElementsFilePathForToken:(NSString*)apiToken {
    return [LQStorage filePathWithExtension:@"ui_elements" forToken:apiToken];
}

+ (void)deleteUIElementsFileForToken:(NSString *)apiToken {
    NSString *filePath = [[self class] uiElementsFilePathForToken:apiToken];
    LQLog(kLQLogLevelInfo, @"<Liquid/UIElementChanger> Deleting cached UI Elements at %@.", filePath);
    NSError *error;
    [LQStorage deleteFileIfExists:filePath error:&error];
    if (error) {
        LQLog(kLQLogLevelError, @"<Liquid/UIElementChanger> Error deleting cached UI Elements at %@", filePath);
    }
}

@end
