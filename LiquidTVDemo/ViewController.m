//
//  ViewController.m
//  LiquidTVDemo
//
//  Created by Miguel M. Almeida on 24/03/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "ViewController.h"
#import "Liquid.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)trackEventButtonPressed:(id)sender {
    [[Liquid sharedInstance] track:@"Button Pressed"];
}

@end
