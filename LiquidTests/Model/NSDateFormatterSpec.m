//
//  NSDateFormatterSpec.m
//  Liquid
//
//  Created by Miguel M. Almeida on 15/10/14.
//  Copyright 2014 Liquid. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "NSDateFormatter+LQDateFormatter.h"


SPEC_BEGIN(NSDateFormatterSpec)

describe(@"NSDateFormatter", ^{
    describe(@"iso8601StringFromDate:", ^{
        it(@"should return an ISO Date string", ^{
            [[[NSDateFormatter iso8601StringFromDate:[NSDate dateWithTimeIntervalSince1970:0]] should] equal:@"1970-01-01T00:00:00.000Z"];
        });
    });

    describe(@"iso8601StringFromDateIOS6:", ^{
        context(@"given a system from Nepal (locale)", ^{
            beforeEach(^{
                NSDateFormatter *stubbedFormatter = [NSDateFormatter alloc];
                [NSDateFormatter stub:@selector(alloc) andReturn:stubbedFormatter];
                stubbedFormatter = [stubbedFormatter init];
                [stubbedFormatter stub:@selector(init) andReturn:stubbedFormatter];
                [stubbedFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ne_NP"]];
            });

            it(@"should return an ISO Date string for", ^{
                [[[NSDateFormatter iso8601StringFromDate:[NSDate dateWithTimeIntervalSince1970:0]] should] equal:@"1970-01-01T00:00:00.000Z"];
            });
        });
    });
});

SPEC_END
