//
//  LQNetworking+NSURLConnection.h
//  Liquid
//
//  Created by Miguel M. Almeida on 16/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQNetworking.h"

@interface LQNetworkingURLConnection : LQNetworking

- (NSInteger)sendData:(NSData *)data toEndpoint:(NSString *)endpoint usingMethod:(NSString *)method;
- (NSData *)getDataFromEndpoint:(NSString *)endpoint;

@end
