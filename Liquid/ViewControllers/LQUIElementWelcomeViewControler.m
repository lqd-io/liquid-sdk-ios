//
//  LQUIElementWelcomeViewControler.m
//  Liquid
//
//  Created by Miguel M. Almeida on 02/02/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "LQUIElementWelcomeView.h"
#import "LQUIElementWelcomeViewControler.h"

@interface LQUIElementWelcomeViewControler ()

@end

@implementation LQUIElementWelcomeViewControler

- (void)viewDidLoad {
    [super viewDidLoad];
    LQUIElementWelcomeView *welcomeView = [[LQUIElementWelcomeView alloc] initWithFrame:self.view.frame];
    [welcomeView.dismissButton addTarget:self action:@selector(dismissButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:welcomeView];
}

- (void)dismissButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
