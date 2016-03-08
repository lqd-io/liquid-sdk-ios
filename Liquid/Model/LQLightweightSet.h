//
//  LQLightweightSet.h
//  Liquid
//
//  Created by Miguel M. Almeida on 08/03/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQWeakValue.h"

@interface LQLightweightSet : NSObject

- (void)addObject:(id)object;
- (void)getExistingWeakValuesWithCompletionHandler:(void(^)(NSArray *weakValues))completionBlock;

@end
