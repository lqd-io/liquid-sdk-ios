//
//  InterfaceController.m
//  LiquidWatchDemo Extension
//
//  Created by Miguel M. Almeida on 14/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "InterfaceController.h"
#import "Liquid.h"

@interface InterfaceController()

@end

static NSArray *uniqueIds;

@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
}

- (void)willActivate {
    [Liquid sharedInstanceWithToken:@"YOUR-APP-TOKEN" development:YES];
    uniqueIds = @[@"100", @"200", @"300", @"anna@example.com", @"mark@example.com"];
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)trackEventButtonPressed {
    [[Liquid sharedInstance] track:@"Watch Button Pressed"];
}

- (IBAction)identifyUserButtonPressed {
    [[Liquid sharedInstance] identifyUserWithIdentifier:[self randomUniqueId]];
}

- (IBAction)resetUserButtonPressed {
    [[Liquid sharedInstance] resetUser];
}

- (NSString *)randomUniqueId {
    uint32_t rnd = arc4random_uniform([uniqueIds count]);
    return [uniqueIds objectAtIndex:rnd];
}

@end
