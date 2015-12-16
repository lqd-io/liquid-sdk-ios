//
//  LQInterceptor.m
//  Liquid
//
//  Created by Miguel M. Almeida on 10/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQDefaults.h"
#import "LQInterceptor.h"
#import "LQTrackableObject.h"
#import <objc/runtime.h>
#import <Aspects/Aspects.h>
#import <UIKit/UIKit.h>
#import "UIView+UIViewPath.h"

@interface LQInterceptor ()

@property (nonatomic, strong) NSSet<LQTrackableObject *> *trackedObjects;

@end

@implementation LQInterceptor

@synthesize trackedObjects = _trackedObjects;

- (NSSet<LQTrackableObject *> *)trackedObjects {
    if (!_trackedObjects) {
        LQTrackableObject *button1 = [[LQTrackableObject alloc] initFromDictionary:@{
                                                              @"path": @"/UIWindow/UIView/UITextView/UITextField/UIButton",
                                                              @"identifier": @"x"
                                                            }];
        LQTrackableObject *button2 = [[LQTrackableObject alloc] initFromDictionary:@{
                                                              @"path": @"/UIWindow/UIView/UIButton",
                                                              @"identifier": @"Track \"Play Music\""
                                                            }];
        _trackedObjects = [NSSet setWithObjects:button1, button2, nil];
    }
    return _trackedObjects;
}

- (void)interceptNewObjects {
    static dispatch_once_t onceToken; // TODO: probably get rid of this
    dispatch_once(&onceToken, ^{
        [UIControl aspect_hookSelector:@selector(didMoveToWindow) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo) {
            id object = [aspectInfo instance];
            if ([object isKindOfClass:[UIButton class]]) {
                [self trackUIButtonIfTrackable:(UIButton *)object];
            }
        } error:NULL];
    });
}

#pragma mark - Tracking UIButton

- (void)trackUIButtonIfTrackable:(UIButton *)button {
    LQTrackableObject *trackedObject = [self trackedObjectFor:button];
    if (trackedObject) { // if button is being tracked
        [button addTarget:self action:@selector(touchUpButton:) forControlEvents:UIControlEventTouchUpInside];
        NSLog(@"Tracking UIButton with path \"%@\" and label \"%@\"", [trackedObject path], button.titleLabel.text);
    }
}

- (void)touchUpButton:(UIButton *)button {
    NSLog(@"Clicked button %@ with path %@ and identifier %@", button.titleLabel.text, [button liquidPath], [button trackableIdentifier]);
}

#pragma mark - Helpers

- (LQTrackableObject *)trackedObjectFor:(UIView *)view {
    for (LQTrackableObject *trackedObject in self.trackedObjects) {
        if ([trackedObject matchesUIView:view]) {
            return trackedObject;
        }
    }
    return nil; // means not being tracked
}

@end
