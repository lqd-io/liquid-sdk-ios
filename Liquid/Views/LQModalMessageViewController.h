//
//  LQModalMessageView.h
//  PopupTest
//
//  Created by Miguel M. Almeida on 19/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQDefaults.h"

#if LQ_INAPP_MESSAGES_SUPPORT
#import <UIKit/UIKit.h>
#import "LQInAppMessageModal.h"
#import "LQCallToAction.h"

typedef void(^MessageDismissBlock)(void);
typedef void(^MessageCTABlock)(LQCallToAction *);

@interface LQModalMessageViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UITextView *messageView;
@property (strong, nonatomic) IBOutlet UIButton *dismissButton;
@property (nonatomic, strong, readonly) NSMutableArray *callsToActionButtons;
@property (nonatomic, strong) LQInAppMessageModal *inAppMessage;
@property (nonatomic, copy) MessageDismissBlock dismissBlock;
@property (nonatomic, copy) MessageCTABlock callToActionBlock;

- (void)defineLayoutWithInAppMessage;

@end
#endif
