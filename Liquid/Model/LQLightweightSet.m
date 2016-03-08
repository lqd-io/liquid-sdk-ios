//
//  LQLightweightSet.m
//  Liquid
//
//  Created by Miguel M. Almeida on 08/03/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "LQLightweightSet.h"
#import "LQDefaults.h"

#define cleaningInterval 20

@interface LQLightweightSet ()

@property (nonatomic, strong) NSMutableSet *set;
@property (atomic, assign) NSInteger cleaningCounter;
#if OS_OBJECT_USE_OBJC
@property(atomic, strong) dispatch_queue_t queue;
#else
@property (atomic, assign) dispatch_queue_t queue;
#endif

@end

@implementation LQLightweightSet

@synthesize set = _set;
@synthesize queue = _queue;
@synthesize cleaningCounter = _cleaningCounter;

- (instancetype)init {
    self = [super self];
    if (self) {
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"%@.%p", kLQBundle, self] UTF8String], DISPATCH_QUEUE_SERIAL);
        _set = [[NSMutableSet alloc] init]; // TODO: with capacity?
        _cleaningCounter = 0;
    }
    return self;
}

- (void)addObject:(id)object {
    dispatch_async(self.queue, ^{
        @synchronized(self.set) {
            if (object) {
                [self.set addObject:[LQWeakValue weakValueWithValue:object]];
                NSLog(@"A new value was added. We now have %lu values", (unsigned long) [self.set count]);
                [self cleanValuesIfNeeded];
            }
        }
    });
}

- (void)getExistingWeakValuesWithCompletionHandler:(void(^)(NSSet *weakValues))completionBlock {
    dispatch_async(self.queue, ^{
        NSSet *weakValues = [[NSSet alloc] init];
        @synchronized(self.set) {
             weakValues = [self getExistingWeakValues];
        }
        completionBlock(weakValues);
    });
}

- (NSSet<LQWeakValue *> *)getExistingWeakValues {
    NSMutableSet *set = [[NSMutableSet alloc] init];
    for (LQWeakValue *weakValue in self.set) {
        if (weakValue.nominalValue) {
            [set addObject:weakValue];
        }
    }
    NSLog(@"There were found %ld values.", (unsigned long) [set count]);
    return [NSSet setWithSet:set];
}

#pragma mark - Helper methods

- (void)cleanValuesIfNeeded {
    if (self.cleaningCounter++ >= cleaningInterval) {
        NSLog(@"More than %d values were added between last cleaning. Cleaning again...", cleaningInterval);
        self.cleaningCounter = 0;
        NSSet *set = [self getExistingWeakValues];
        if (kLQLogLevel >= kLQLogLevelInfoVerbose) {
            NSString *msg = [NSString stringWithFormat:@"Cleaned. We had %ld and have %ld values now.", (unsigned long) [self.set count], (unsigned long) [set count]];
            if ([set count] < [self.set count]) {
                msg = [NSString stringWithFormat:@"%@ Reduced by %d", msg, ([self.set count] - [set count])];
            }
            LQLog(kLQLogLevelInfoVerbose, msg);
        }
        self.set = [NSMutableSet setWithSet:set];
    }
}

@end
