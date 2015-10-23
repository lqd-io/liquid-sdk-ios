//
//  LQModalMessageView.h
//  PopupTest
//
//  Created by Miguel M. Almeida on 19/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LQModalMessageViewDelegate <NSObject>

@optional
- (void)modalMessageDismiss;
- (void)modalMessageCTA1;
- (void)modalMessageCTA2;
@end

@interface LQModalMessageView : UIView

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UITextView *messageView;
@property (strong, nonatomic) IBOutlet UIButton *cta1Button;
@property (strong, nonatomic) IBOutlet UIButton *cta2Button;
@property (strong, nonatomic) IBOutlet UIButton *xButton;

@property (nonatomic, strong) NSObject <LQModalMessageViewDelegate> *delegate;

@end
