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

@property (nonatomic, strong) LQUIElementWelcomeView *welcomeView;

@end

@implementation LQUIElementWelcomeViewControler

@synthesize welcomeView = _welcomeView;

#pragma mark - Initializers

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.welcomeView];
    [self.welcomeView.dismissButton addTarget:self action:@selector(dismissButtonPressed:)
                             forControlEvents:UIControlEventTouchUpInside];
    [self downloadAssets];
}

- (LQUIElementWelcomeView *)welcomeView {
    if (!_welcomeView) {
        _welcomeView = [[LQUIElementWelcomeView alloc] initWithFrame:self.view.frame];
        _welcomeView.frame = self.view.bounds;
    }
    return _welcomeView;
}

#pragma mark - Targets

- (void)dismissButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helper methods

- (void)downloadAssets {
    self.welcomeView.backgroundImageView.image = [self getImageFromURL:@"https://s3-eu-west-1.amazonaws.com/lqd-io/public/event_tracking/add_event_phone_sketch.png"];
    self.welcomeView.checkImageView.image = [self getImageFromURL:@"https://s3-eu-west-1.amazonaws.com/lqd-io/public/event_tracking/check.png"];
}

- (UIImage *)getImageFromURL:(NSString *)fileURL { // TODO: move to Controller
    return [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:fileURL]]];
}

@end
