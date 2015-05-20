//
//  LQDeviceSpec.m
//  Liquid
//
//  Created by Miguel M. Almeida on 21/05/15.
//  Copyright 2015 Liquid. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "LQDevicePrivates.h"
#import "LQKeychain.h"
#import "LQUserDefaults.h"
#import "NSString+LQString.h"

SPEC_BEGIN(LQDeviceSpec)

describe(@"LQDevice", ^{
    describe(@"uniqueId", ^{
        let(randomUUID, ^id{
            return [NSString generateRandomUUID];
        });

        beforeEach(^{
            SecItemDelete((__bridge CFDictionaryRef) @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword});
            [LQDevice deleteUniqueIdFile];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"io.lqd.ios.UUID"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        });

        context(@"given no uniqueId stored anywhere", ^{
            it(@"generates a new UniqueId", ^{
                [[LQDevice should] receive:@selector(generateDeviceUID)];
                [LQDevice uniqueId];
            });

            it(@"returns the same uniqueId if called twice", ^{
                NSString *uniqueId = [LQDevice uniqueId];
                [[uniqueId should] equal:[LQDevice uniqueId]];
            });
        });

        context(@"given a uniqueId stored in a file", ^{
            beforeEach(^{
                [NSKeyedArchiver archiveRootObject:randomUUID toFile:[LQDevice uniqueIdFile]];
            });

            it(@"retrieves the uniqueId from the file", ^{
                [[[LQDevice uniqueId] should] equal:randomUUID];
            });

            it(@"returns the same uniqueId if called twice", ^{
                [LQDevice uniqueId];
                [[[LQDevice uniqueId] should] equal:randomUUID];
            });
        });

        context(@"given a uniqueId stored in NSUserDefaults", ^{
            beforeEach(^{
                [[NSUserDefaults standardUserDefaults] setObject:randomUUID forKey:@"io.lqd.ios.UUID"];
            });

            it(@"retrieves the uniqueId from the NSUserDefaults if called once (retrocompatibility test)", ^{
                [[[LQDevice uniqueIdFromKeychain] should] beNil];
                [[[LQDevice uniqueIdFromNSUserDefaults] shouldNot] beNil];
                [LQDevice uniqueId];
            });

            it(@"returns the same uniqueId if called twice", ^{
                NSString *uniqueId = [LQDevice uniqueId];
                [[uniqueId should] equal:[LQDevice uniqueId]];
            });

            it(@"returns the same uniqueId that was stored in NSUserDefaults", ^{
                [[[LQDevice uniqueId] should] equal:randomUUID];
            });

            it(@"returns the same uniqueId that was stored in NSUserDefaults, if called twice", ^{
                [LQDevice uniqueId];
                [[[LQDevice uniqueId] should] equal:randomUUID];
            });
        });
    });
    
    describe(@"init", ^{
        context(@"given no uniqueId stored anywhere", ^{
            beforeEach(^{
                SecItemDelete((__bridge CFDictionaryRef) @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword});
                [LQDevice deleteUniqueIdFile];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"io.lqd.ios.UUID"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            });

            it(@"has no key stored in Keychain", ^{
                [[[LQKeychain valueForKey:@"device.unique_id"] should] beNil];
            });

            it(@"stores the uniqueId in Keychain", ^{
                LQDevice __attribute__((unused)) *device = [[LQDevice alloc] init];
                [[[LQKeychain valueForKey:@"device.unique_id"] shouldNot] beNil];
            });

            it(@"has no key stored in a file", ^{
                [[[LQDevice unarchiveUniqueId] should] beNil];
            });

            it(@"stores the uniqueId in a file", ^{
                LQDevice __attribute__((unused)) *device = [[LQDevice alloc] init];
                [[[LQDevice unarchiveUniqueId] shouldNot] beNil];
            });

            it(@"has no key stored in NSUserDefaults", ^{
                [[[[NSUserDefaults standardUserDefaults] objectForKey:@"io.lqd.ios.UUID"] should] beNil];
            });

            it(@"stores the uniqueId in NSUserDefaults", ^{
                LQDevice __attribute__((unused)) *device = [[LQDevice alloc] init];
                [[[[NSUserDefaults standardUserDefaults] objectForKey:@"io.lqd.ios.UUID"] shouldNot] beNil];
            });
        });
    });
});

SPEC_END
