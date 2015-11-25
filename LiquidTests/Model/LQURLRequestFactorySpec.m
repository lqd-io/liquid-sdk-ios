//
//  LQURLRequestFactory.m
//  Liquid
//
//  Created by Miguel M. Almeida on 06/09/14.
//  Copyright 2014 Liquid. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "LQURLRequestFactory.h"
#import "LQDeviceIOS.h"
#import "LQStorage.h"

SPEC_BEGIN(LQURLRequestFactorySpec)

describe(@"LQURLRequestFactory", ^{
    beforeEach(^{
        [LQStorage deleteAllLiquidFiles];
    });

    describe(@"liquidUserAgent", ^{
        it(@"should return a valid User-Agent", ^{
            LQDevice *device = [[LQDeviceIOS alloc] init];
            [device stub:@selector(liquidVersion) andReturn:@"0.8.0-beta"];
            [device stub:@selector(systemVersion) andReturn:@"7.1"];
            [device stub:@selector(systemLanguage) andReturn:@"en"];
            [device stub:@selector(locale) andReturn:@"pt_PT"];
            [device stub:@selector(deviceModel) andReturn:@"iPhone5,2"];
            [LQDevice stub:@selector(sharedInstance) andReturn:device];
            [[[LQURLRequestFactory liquidUserAgent] should] equal:@"Liquid/0.8.0-beta (iOS; iOS 7.1; pt_PT; iPhone5,2)"];
        });
    });
});

SPEC_END
