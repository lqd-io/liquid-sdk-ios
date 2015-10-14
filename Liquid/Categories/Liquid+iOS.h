//
//  Liquid+iOS.h
//  Liquid
//
//  Created by Miguel M. Almeida on 15/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "Liquid.h"

@interface Liquid (iOS)

- (void)bindNotifications;
- (void)beginBackgroundUpdateTask;
- (void)endBackgroundUpdateTask;
- (void)initializeBackgroundTaskIdentifier;

@end
