//
//  LQSlideUpView.h
//  Liquid
//
//  Created by Miguel M. Almeida on 29/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQDefaults.h"

#if LQ_INAPP_MESSAGES_SUPPORT
#import <UIKit/UIKit.h>

typedef void(^CompletionBlock)();

@interface LQSlideUpView : UIView

@property (nonatomic, copy) CompletionBlock showAnimationCompletedBlock;
@property (nonatomic, copy) CompletionBlock hideAnimationCompletedBlock;

- (void)presentInWindow:(UIWindow *)window;
- (void)dismiss;
+ (instancetype)slideUpWithContentViewController:(UIViewController *)contentViewController;

@end
#endif
