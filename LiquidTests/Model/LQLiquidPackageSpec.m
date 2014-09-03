//
//  LQLiquidPackageSpec.m
//  Liquid
//
//  Created by Liquid Liquid Data Intelligence, S.A. (lqd.io) on 06/08/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "LQLiquidPackage.h"
#import "LQVariable.h"
#import "LQValue.h"
#import "LQStorage.h"

SPEC_BEGIN(LQLiquidPackageSpec)

describe(@"LQLiquidPackage", ^{
    beforeEach(^{
        [LQStorage deleteAllLiquidFiles];
    });

    describe(@"valueForKey:error:", ^{
        context(@"given a Liquid Package with a value for a String Variable", ^{
            __block LQLiquidPackage *liquidPackage;

            beforeEach(^{
                LQVariable *variable = [[LQVariable alloc] initWithName:@"title" dataType:@"string"];
                LQValue *value = [[LQValue alloc] initWithValue:@"Welcome to Liquid" variable:variable];
                liquidPackage = [[LQLiquidPackage alloc] initWithValues:[NSArray arrayWithObject:value]];
            });

            it(@"should return the nominal value of the Value", ^{
                NSError *error;
                LQValue *liquidValue = [liquidPackage valueForKey:@"title" error:&error];
                [[liquidValue.value should] equal:@"Welcome to Liquid"];
            });
        });

        context(@"given a Liquid Package with a Null value", ^{
            __block LQLiquidPackage *liquidPackage;

            beforeEach(^{
                LQVariable *variable = [[LQVariable alloc] initWithName:@"title" dataType:@"string"];
                LQValue *value = [[LQValue alloc] initWithValue:[NSNull null] variable:variable];
                liquidPackage = [[LQLiquidPackage alloc] initWithValues:[NSArray arrayWithObject:value]];
            });

            it(@"should return nil", ^{
                NSError *error;
                LQValue *liquidValue = [liquidPackage valueForKey:@"title" error:&error];
                [[liquidValue should] beNil];
            });
        });
    });
});

SPEC_END
