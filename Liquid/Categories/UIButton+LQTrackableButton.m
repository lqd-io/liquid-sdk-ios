//
//  UIButton+LQTrackableButton.m
//  Liquid
//
//  Created by Miguel M. Almeida on 15/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "UIButton+LQTrackableButton.h"

@implementation UIButton (LQTrackableButton)

- (NSString *)trackableIdentifier {
    return self.titleLabel.text;
}

@end
