//
//  Liquid.m
//  Liquid
//
//  Created by Liquid Liquid Data Intelligence, S.A. (lqd.io) on 14/07/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Kiwi/Kiwi.h>

#import "LQUserPrivates.h"

SPEC_BEGIN(LQUserSpec)

describe(@"LQUser", ^{
    context(@"given an identified user", ^{
        __block LQUser *user;
        
        beforeEach(^{
            user = [[LQUser alloc] initWithIdentifier:@"audreytautou@gmail.com" attributes:nil];
        });

        it(@"should have the correct unique ID", ^{
            [[user.identifier should] equal:@"audreytautou@gmail.com"];
        });

        it(@"should have the User's isIdentified field set to @YES", ^{
            [[user.identified should] equal:@YES];
        });

        it(@"should have the User's isIdentified field set to YES", ^{
            [[theValue(user.isIdentified) should] equal:[NSNumber numberWithBool:YES]];
        });

        it(@"should include the correct value for the 'unique_id' key on the JSON object", ^{
            [[[[user jsonDictionary] objectForKey:@"unique_id"] should] equal:@"audreytautou@gmail.com"];
        });

        it(@"should include the value for the 'identified' key on the JSON object set to YES", ^{
            [[[[user jsonDictionary] objectForKey:@"identified"] should] equal:@YES];
        });
    });

    context(@"given an identified user", ^{
        __block LQUser *user;

        beforeEach(^{
            user = [[LQUser alloc] initWithIdentifier:nil attributes:nil];
        });

        it(@"should have the User's identified field set to @NO", ^{
            [[user.identified should] equal:@NO];
        });

        it(@"should have the User's isIdentified field set to NO", ^{
            [[theValue(user.isIdentified) should] equal:[NSNumber numberWithBool:NO]];
        });

        it(@"should include the value for the 'identified' key on the JSON object set to @NO", ^{
            [[[[user jsonDictionary] objectForKey:@"identified"] should] equal:@NO];
        });
    });
    
});

SPEC_END
