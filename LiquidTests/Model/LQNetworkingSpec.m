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

SPEC_BEGIN(LQNetworkingSpec)

describe(@"LQNetworking", ^{
    describe(@"liquidUserAgent", ^{
        it(@"should return a valid User-Agent", ^{
            [LQDevice stub:@selector(liquidVersion) andReturn:@"0.8.0-beta"];
            [LQDevice stub:@selector(systemVersion) andReturn:@"7.1"];
            [LQDevice stub:@selector(systemLanguage) andReturn:@"en"];
            [LQDevice stub:@selector(locale) andReturn:@"pt_PT"];
            [LQDevice stub:@selector(deviceModel) andReturn:@"iPhone5,2"];
            [[[LQNetworking liquidUserAgent] should] equal:@"Liquid/0.8.0-beta (iOS; iOS 7.1; pt_PT; iPhone5,2)"];
        });
    });
});

SPEC_END
