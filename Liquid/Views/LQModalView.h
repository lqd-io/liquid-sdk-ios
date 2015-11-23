//
//  LQMessageView.h
//  PopupTest
//
//  Created by Miguel M. Almeida on 18/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQDefaults.h"

#if LQ_INAPP_MESSAGES_SUPPORT
#import <UIKit/UIKit.h>

typedef void(^CompletionBlock)();

@interface LQModalView : UIView

@property (nonatomic, copy) CompletionBlock showAnimationCompletedBlock;
@property (nonatomic, copy) CompletionBlock hideAnimationCompletedBlock;

- (void)presentInWindow:(UIWindow *)window;
- (void)dismiss;
+ (instancetype)modalWithContentView:(UIViewController *)contentViewController;

@end
#endif
