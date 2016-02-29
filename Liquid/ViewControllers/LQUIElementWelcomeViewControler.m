//
//  LQUIElementWelcomeViewControler.m
//  Liquid
//
//  Created by Miguel M. Almeida on 02/02/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "LQUIElementWelcomeViewControler.h"

#define SKETCH_IMG_URL @"https://s3-eu-west-1.amazonaws.com/lqd-io/public/event_tracking/add_event_phone_sketch.png"
#define CHECK_IMG_URL @"https://s3-eu-west-1.amazonaws.com/lqd-io/public/event_tracking/check.png"

@interface LQUIElementWelcomeViewControler ()

@end

@implementation LQUIElementWelcomeViewControler

@synthesize welcomeView = _welcomeView;

#pragma mark - Initializers

- (instancetype)init {
    self = [super init];
    if (self) {
        [self downloadAssets];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.welcomeView];
    [self.welcomeView.dismissButton addTarget:self action:@selector(dismissButtonPressed:)
                             forControlEvents:UIControlEventTouchUpInside];
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
    [[[NSURLSession sharedSession] downloadTaskWithURL:[NSURL URLWithString:SKETCH_IMG_URL] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (!error) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.welcomeView.sketchImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];
            });
        }
    }] resume];
    [[[NSURLSession sharedSession] downloadTaskWithURL:[NSURL URLWithString:CHECK_IMG_URL] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (!error) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.welcomeView.checkImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];
            });
        }
    }] resume];
}

- (UIImage *)getImageFromURL:(NSString *)fileURL {
    return [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:fileURL]]];
}

@end
