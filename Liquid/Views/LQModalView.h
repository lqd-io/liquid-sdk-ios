//
//  LQMessageView.h
//  PopupTest
//
//  Created by Miguel M. Almeida on 18/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LQModalView : UIView

- (void)presentModal;
- (void)dismissModal;
+ (LQModalView *)modalWithContentView:(UIView *)contentView;

@end
