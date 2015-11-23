//
//  LQSlideUpMessageView.h
//  Liquid
//
//  Created by Miguel M. Almeida on 29/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQDefaults.h"

#if LQ_INAPP_MESSAGES_SUPPORT
#import <UIKit/UIKit.h>
#import "LQInAppMessageSlideUp.h"
#import "LQCallToAction.h"

typedef void(^MessageDismissBlock)(void);
typedef void(^MessageCTABlock)(LQCallToAction *);

@interface LQSlideUpMessageViewController : UIViewController <UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UITextView *messageView;
@property (strong, nonatomic) IBOutlet UIButton *callToAction;
@property (nonatomic, strong) LQInAppMessageSlideUp *inAppMessage;
@property (nonatomic, copy) MessageDismissBlock dismissBlock;
@property (nonatomic, copy) MessageCTABlock callToActionBlock;
@property (nonatomic, copy, readonly) NSNumber *height;

- (void)defineLayoutWithInAppMessage;

@end
#endif
