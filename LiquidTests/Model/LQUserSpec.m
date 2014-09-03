//
//  Liquid.m
//  Liquid
//
//  Created by Liquid Liquid Data Intelligence, S.A. (lqd.io) on 14/07/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Kiwi/Kiwi.h>

#import "LQUserPrivates.h"
#import "LQStorage.h"

SPEC_BEGIN(LQUserSpec)

describe(@"LQUser", ^{
    beforeEach(^{
        [LQStorage deleteAllLiquidFiles];
    });

    describe(@"copy", ^{
        context(@"given copying an user", ^{
            __block LQUser *user1;
            __block LQUser *user2;
            
            beforeEach(^{
                user1 = [[LQUser alloc] initWithIdentifier:@"123" attributes:[NSDictionary dictionaryWithObjectsAndKeys:@29, @"age", nil]];
                user2 = [user1 copy];
            });

            it(@"should copy the object and keep the identifier", ^{
                [[user2.identifier should] equal:@"123"];
            });
            
            context(@"given changing the identifier of the copy", ^{
                beforeEach(^{
                    user2.identifier = @"456";
                });

                it(@"should keep the identifier of the original user", ^{
                    [[user1.identifier should] equal:@"123"];
                });

                it(@"should change the identifier of the copy", ^{
                    [[user2.identifier should] equal:@"456"];
                });
            });

            context(@"given changing the age attribute of original user", ^{
                beforeEach(^{
                    user1.attributes = [NSDictionary dictionaryWithObjectsAndKeys:@30, @"age", nil];
                });

                it(@"should change the age attribute of original user", ^{
                    [[[user1.attributes objectForKey:@"age"] should] equal:@30];
                });

                it(@"should not change the age attribute of copied user", ^{
                    [[[user2.attributes objectForKey:@"age"] should] equal:@29];
                });
            });
        });
    });

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

        it(@"should have the User's isIdentified method set to YES", ^{
            [[theValue([user isIdentified]) should] beYes];
        });

        it(@"should include the correct value for the 'unique_id' key on the JSON object", ^{
            [[[[user jsonDictionary] objectForKey:@"unique_id"] should] equal:@"audreytautou@gmail.com"];
        });

        it(@"should include the value for the 'identified' key on the JSON object set to YES", ^{
            [[[[user jsonDictionary] objectForKey:@"identified"] should] equal:@YES];
        });
    });

    context(@"given an anonymous user", ^{
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

    describe(@"isIdentified", ^{
        context(@"given an identifier user", ^{
            __block LQUser *user;
            
            beforeEach(^{
                user = [[LQUser alloc] initWithIdentifier:@"audreytautou@gmail.com" attributes:nil];
            });
            
            it(@"should return YES", ^{
                [[theValue([user isIdentified]) should] beYes];
            });
        });

        context(@"given an anonymous user", ^{
            __block LQUser *user;
            
            beforeEach(^{
                user = [[LQUser alloc] initWithIdentifier:nil attributes:nil];
            });
            
            it(@"should return NO", ^{
                [[theValue([user isIdentified]) should] beNo];
            });
        });
    });

    describe(@"isAnonymous", ^{
        context(@"given an identifier user", ^{
            __block LQUser *user;
            
            beforeEach(^{
                user = [[LQUser alloc] initWithIdentifier:@"audreytautou@gmail.com" attributes:nil];
            });
            
            it(@"should return NO", ^{
                [[theValue([user isAnonymous]) should] beNo];
            });
        });
        
        context(@"given an anonymous user", ^{
            __block LQUser *user;
            
            beforeEach(^{
                user = [[LQUser alloc] initWithIdentifier:nil attributes:nil];
            });
            
            it(@"should return YES", ^{
                [[theValue([user isAnonymous]) should] beYes];
            });
        });
    });
});

SPEC_END
