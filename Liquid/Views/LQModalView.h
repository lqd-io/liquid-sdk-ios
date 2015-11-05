//
//  LQMessageView.h
//  PopupTest
//
//  Created by Miguel M. Almeida on 18/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^CompletionBlock)();

@interface LQModalView : UIView

@property (nonatomic, copy) CompletionBlock showAnimationCompletedBlock;
@property (nonatomic, copy) CompletionBlock hideAnimationCompletedBlock;

- (void)presentInWindow:(UIWindow *)window;
- (void)dismissModal;
+ (instancetype)modalWithContentView:(UIViewController *)contentViewController;

@end
