//
//  LQLightweightSet.m
//  Liquid
//
//  Created by Miguel M. Almeida on 08/03/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "LQLightweightSet.h"
#import "LQDefaults.h"

#define cleaningInterval 40
#define arrayMaxLength 250

@interface LQLightweightSet ()

@property (nonatomic, strong) NSMutableArray *array;
@property (atomic, assign) NSInteger cleaningCounter;
#if OS_OBJECT_USE_OBJC
@property(atomic, strong) dispatch_queue_t queue;
#else
@property (atomic, assign) dispatch_queue_t queue;
#endif

@end

@implementation LQLightweightSet

@synthesize array = _array;
@synthesize queue = _queue;
@synthesize cleaningCounter = _cleaningCounter;

- (instancetype)init {
    self = [super self];
    if (self) {
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"%@.%p", kLQBundle, self] UTF8String], DISPATCH_QUEUE_SERIAL);
        _array = [[NSMutableArray alloc] init];
        _cleaningCounter = 0;
    }
    return self;
}

- (void)addObject:(id)object {
    dispatch_async(self.queue, ^{
        @synchronized(self.array) {
            if (object) {
                [self.array addObject:[LQWeakValue weakValueWithValue:object]];
                LQLog(kLQLogLevelInfoVerbose, @"<Liquid/LightweightSet> A new value was added. We now have %lu values", (unsigned long) [self.array count]);
                [self cleanValuesIfNeeded];
            }
        }
    });
}

- (void)getExistingWeakValuesWithCompletionHandler:(void(^)(NSArray *weakValues))completionBlock {
    dispatch_async(self.queue, ^{
        NSArray *weakValues = [[NSArray alloc] init];
        @synchronized(self.array) {
             weakValues = [self getExistingWeakValues];
        }
        completionBlock(weakValues);
    });
}

- (NSArray<LQWeakValue *> *)getExistingWeakValues {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSUInteger i = 0;
    for (LQWeakValue *weakValue in [self.array reverseObjectEnumerator]) {
        if (weakValue.nominalValue) {
            [array addObject:weakValue];
        }
        if (i++ == arrayMaxLength) {
            LQLog(kLQLogLevelInfoVerbose, @"<Liquid/LightweightSet> Max number of elements for array was hit (%d). Ignoring the oldest ones.", arrayMaxLength);
            break;
        }
    }
    return [NSArray arrayWithArray:array];
}

#pragma mark - Helper methods

- (void)cleanValuesIfNeeded {
    if (self.cleaningCounter++ >= cleaningInterval) {
        LQLog(kLQLogLevelInfoVerbose, @"<Liquid/LightweightSet> More than %d values were added between last cleaning. Cleaning now...", cleaningInterval);
        self.cleaningCounter = 0;
        NSArray *array = [self getExistingWeakValues];
        if (kLQLogLevel >= kLQLogLevelInfoVerbose) {
            LQLog(kLQLogLevelInfoVerbose, @"<Liquid/LightweightSet> Cleaned. We had %ld and have %ld values now.",
                  (unsigned long) [self.array count], (unsigned long) [array count]); // TODO: msg
            if ([array count] < [self.array count]) {
                LQLog(kLQLogLevelInfoVerbose, @"<Liquid/LightweightSet> Set was reduced by %d", ([self.array count] - [array count]));
            }
        }
        self.array = [NSMutableArray arrayWithArray:array];
    }
}

@end
