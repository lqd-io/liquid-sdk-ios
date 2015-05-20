//
//  LQKeychainSpec.m
//  Liquid
//
//  Created by Miguel M. Almeida on 21/05/15.
//  Copyright 2015 Liquid. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "LQKeychainPrivates.h"

SPEC_BEGIN(LQKeychainSpec)

describe(@"LQKeychain", ^{
    beforeEach(^{
        SecItemDelete((__bridge CFDictionaryRef) @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword});
    });

    describe(@"setValue:forKey:allowUpdate:", ^{
        context(@"given no values in Keychain", ^{
            it(@"sets the value in Keychain if allowUpdate is YES", ^{
                [[[LQKeychain valueForKey:@"aKey"] should] beNil];
                [LQKeychain setValue:@"aValue" forKey:@"aKey" allowUpdate:YES];
                [[[LQKeychain valueForKey:@"aKey"] should] equal:@"aValue"];
            });

            it(@"sets the value in Keychain if allowUpdate is NO", ^{
                [[[LQKeychain valueForKey:@"aKey"] should] beNil];
                [LQKeychain setValue:@"aValue" forKey:@"aKey" allowUpdate:NO];
                [[[LQKeychain valueForKey:@"aKey"] should] equal:@"aValue"];
            });
        });

        context(@"given a value already in Keychain", ^{
            beforeEach(^{
                [LQKeychain setValue:@"oldValue" forKey:@"aKey" allowUpdate:NO];
            });

            it(@"sets a new value in Keychain if allowUpdate is YES", ^{
                [LQKeychain setValue:@"newValue" forKey:@"aKey" allowUpdate:YES];
                [[[LQKeychain valueForKey:@"aKey"] should] equal:@"newValue"];
            });

            it(@"keeps the old value in Keychain if allowUpdate is NO", ^{
                [LQKeychain setValue:@"newValue" forKey:@"aKey" allowUpdate:NO];
                [[[LQKeychain valueForKey:@"aKey"] should] equal:@"oldValue"];
            });
        });
    });

    describe(@"value:forKey:", ^{
        context(@"given no values in Keychain", ^{
            it(@"returns nil", ^{
            });
        });

        context(@"given a uniqueId in Keychain", ^{
            it(@"returns the stored uniqueId", ^{
            });
        });
    });

    describe(@"liquidNameSpace", ^{
        it(@"returns the correct liquid namespace", ^{
            [[[LQKeychain liquidNameSpace] should] equal:@"io.lqd.ios.keychain"];
        });
    });
});

SPEC_END
