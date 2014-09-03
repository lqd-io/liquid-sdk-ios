//
//  LQNetworkingSpec.m
//  Liquid
//
//  Created by Miguel M. Almeida on 06/09/14.
//  Copyright 2014 Liquid. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "LQNetworking.h"
#import "LQDevice.h"
#import "LQStorage.h"

SPEC_BEGIN(LQNetworkingSpec)

describe(@"LQNetworking", ^{
    beforeEach(^{
        [LQStorage deleteAllLiquidFiles];
    });

    describe(@"liquidUserAgent", ^{
        it(@"should return a valid User-Agent", ^{
            LQDevice *device = [[LQDevice alloc] init];
            [device stub:@selector(liquidVersion) andReturn:@"0.8.0-beta"];
            [device stub:@selector(systemVersion) andReturn:@"7.1"];
            [device stub:@selector(systemLanguage) andReturn:@"en"];
            [device stub:@selector(locale) andReturn:@"pt_PT"];
            [device stub:@selector(deviceModel) andReturn:@"iPhone5,2"];
            [LQDevice stub:@selector(sharedInstance) andReturn:device];
            [[[LQNetworking liquidUserAgent] should] equal:@"Liquid/0.8.0-beta (iOS; iOS 7.1; pt_PT; iPhone5,2)"];
        });
    });
});

SPEC_END
