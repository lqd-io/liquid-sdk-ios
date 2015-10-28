//
//  LQModalMessageView.h
//  PopupTest
//
//  Created by Miguel M. Almeida on 19/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LQInAppMessageModal.h"
#import "LQCallToAction.h"

typedef void(^ModalMessageDismissBlock)(void);
typedef void(^ModalMessageCTABlock)(LQCallToAction *);

@interface LQModalMessageView : UIView

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UITextView *messageView;
@property (strong, nonatomic) IBOutlet UIButton *dismissButton;
@property (nonatomic, strong, readonly) NSMutableArray *callsToActionButtons;
@property (nonatomic, strong) LQInAppMessageModal *inAppMessage;
@property (nonatomic, copy) ModalMessageDismissBlock modalDismissBlock;
@property (nonatomic, copy) ModalMessageCTABlock modalCTABlock;

- (void)defineLayoutWithInAppMessage;

@end
