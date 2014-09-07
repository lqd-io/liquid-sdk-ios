//
//  ViewController.h
//  Liquid
//
//  Created by Liquid Liquid Data Intelligence, S.A. (lqd.io) on 12/06/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Liquid.h"

@interface LiquidDemoViewController : UIViewController <LiquidDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITextField *customEventNameTextField;
@property (strong, nonatomic) IBOutlet UIView *bgColorSquare;
@property (strong, nonatomic) IBOutlet UILabel *bgColorLabel;
@property (strong, nonatomic) IBOutlet UILabel *showAdsLabel;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UISwitch *autoLoadValuesSwitch;
@property (strong, nonatomic) IBOutlet UIButton *loadValuesButton;
@property (strong, nonatomic) IBOutlet UISegmentedControl *userSelectorSegmentedControl;
@property (strong, nonatomic) IBOutlet UITableView *userAttributesTableView;
@property (strong, nonatomic) IBOutlet UILabel *userUniqueId;
@property (strong, nonatomic) IBOutlet UIButton *anonymousUserButton;

@end
