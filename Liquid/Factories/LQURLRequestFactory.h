//
//  LQURLRequestFactory.h
//  Liquid
//
//  Created by Miguel M. Almeida on 16/11/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LQURLRequestFactory : NSObject

- (instancetype)initWithAppToken:(NSString *)appToken;
- (NSMutableURLRequest *)buildRequestWithMethod:(NSString *)method forEndpoint:(NSString *)endpoint;
+ (NSString *)liquidUserAgent;

@end
