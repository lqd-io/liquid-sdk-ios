//
//  LQURLRequestFactory.m
//  Liquid
//
//  Created by Miguel M. Almeida on 16/11/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQURLRequestFactory.h"
#import "LQDevice.h"
#import "LQDefaults.h"
#import "LQDate.h"
#import "NSDate+LQDateFormats.h"

#define kLQServerUrl @"https://api.lqd.io/collect/"

@interface LQURLRequestFactory ()

@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) NSString *liquidUserAgent;
@property (nonatomic, strong) NSString *appToken;

@end

@implementation LQURLRequestFactory

NSString * const serverUrl = kLQServerUrl;

@synthesize appToken = _appToken;
@synthesize liquidUserAgent = _liquidUserAgent;
@synthesize headers = _headers;

#pragma mark - Initializers

- (instancetype)initWithAppToken:(NSString *)appToken {
    self = [super init];
    if (self) {
        _appToken = appToken;
        
    }
    return self;
}

#pragma mark - Public methods

- (NSMutableURLRequest *)buildRequestWithMethod:(NSString *)method forEndpoint:(NSString *)endpoint {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self serverURLForEndpoint:endpoint]]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:10.0f];
    for (NSString *header in [self headers]) {
        [request setValue:[[self headers] objectForKey:header] forHTTPHeaderField:header];
    }
    [request setHTTPMethod:method];
    return request;
}

#pragma mark - Halper methods

- (NSDictionary *)headers {
    if (!_headers) {
        _headers = @{
                     @"Accept": @"application/vnd.lqd.v1+json",
                     @"Content-Type": @"application/json",
                     @"Accept-Encoding": @"gzip",
                     @"User-Agent": self.liquidUserAgent,
                     @"Authorization": [NSString stringWithFormat:@"Token %@", self.appToken],
                     @"Date": [self dateHeader]
                    };
    }
    return _headers;
}

- (NSString *)serverURLForEndpoint:(NSString *)endpoint {
    return [NSString stringWithFormat:@"%@%@", serverUrl, endpoint];
}

- (NSString *)liquidUserAgent {
    if(!_liquidUserAgent) {
        _liquidUserAgent = [[self class] liquidUserAgent];
    }
    return _liquidUserAgent;
}

- (NSString *)dateHeader {
    return [[LQDate currentNow] rfc1123String];
}

#pragma mark - Class methods

+ (NSString *)liquidUserAgent {
    LQDevice *device = [LQDevice sharedInstance];
    return [NSString stringWithFormat:@"Liquid/%@ (%@; %@ %@; %@; %@)", [device liquidVersion],
            [device platform],
            [device platform], [device systemVersion],
            [device locale],
            [device deviceModel]
            ];
}

@end
