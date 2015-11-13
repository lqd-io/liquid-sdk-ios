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

- (void)requestData:(NSData *)data toEndpoint:(NSString *)endpoint usingMethod:(NSString *)method completionHandler:(void(^)(LQQueueStatus queueStatus, NSData * _Nullable responseData))completionHandler {
    NSString *fullUrl = [NSString stringWithFormat:@"%@%@", serverUrl, endpoint];
    NSURL *url = [NSURL URLWithString:fullUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:10.0f];
    [request setHTTPMethod:method];
    [request setValue:[NSString stringWithFormat:@"Token %@", self.appToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:self.liquidUserAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/vnd.lqd.v1+json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[data length]] forHTTPHeaderField:@"Content-Length"];
    if (data) {
        [request setHTTPBody:data];
    }

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            if (error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorCannotConnectToHost || error.code == NSURLErrorNetworkConnectionLost) {
                LQLog(kLQLogLevelHttpError, @"<Liquid> Error (%ld) while sending data to server: Server is unreachable", (long)error.code);
                if (completionHandler) completionHandler(LQQueueStatusOk, data);
            } else if(error.code == NSURLErrorUserCancelledAuthentication || error.code == NSURLErrorUserAuthenticationRequired) {
                LQLog(kLQLogLevelHttpError, @"<Liquid> Error (%ld) while sending data to server: Unauthorized (check App Token)", (long)error.code);
                if (completionHandler) completionHandler(LQQueueStatusUnauthorized, data);
            } else {
                LQLog(kLQLogLevelHttpError, @"<Liquid> Error (%ld) while sending data to server: Server error", (long)error.code);
                if (completionHandler) completionHandler(LQQueueStatusRejected, data);
            }
        } else {
            if (kLQLogLevel == kLQLogLevelHttpData) {
                NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                LQLog(kLQLogLevelHttpData, @"<Liquid> Response from server: %@", responseString);
            }
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if(httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                if (completionHandler) completionHandler(LQQueueStatusOk, data);
            } else {
                LQLog(kLQLogLevelHttpError, @"<Liquid> Error (%ld) while sending data to server: Server error", (long)httpResponse.statusCode);
                if (completionHandler) completionHandler(LQQueueStatusRejected, data);
            }
        }
    }];
}

@end
