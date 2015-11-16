//
//  LQNetworking+NSURLConnection.m
//  Liquid
//
//  Created by Miguel M. Almeida on 16/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQNetworkingURLConnection.h"
#import "LQNetworkingProtected.h"

@implementation LQNetworkingURLConnection

- (void)requestData:(NSData *)data toEndpoint:(NSString *)endpoint usingMethod:(NSString *)method completionHandler:(void(^)(LQQueueStatus queueStatus, NSData *responseData))completionHandler {
    NSMutableURLRequest *request = [self.urlRequestFactory buildRequestWithMethod:method forEndpoint:endpoint];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[data length]] forHTTPHeaderField:@"Content-Length"];
    if (data) {
        [request setHTTPBody:data];
    }
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
        LQQueueStatus status = [[self class] queueStatusFromData:responseData response:response error:error];
        completionHandler(status, responseData);
    }];
}

@end
