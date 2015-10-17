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

- (NSInteger)sendData:(NSData *)data toEndpoint:(NSString *)endpoint usingMethod:(NSString *)method {
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
    [request setHTTPBody:data];
    
    NSURLResponse *response;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&error];
    NSString __unused *responseString = [[NSString alloc] initWithData:responseData
                                                              encoding:NSUTF8StringEncoding];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (error) {
        if (error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorCannotConnectToHost || error.code == NSURLErrorNetworkConnectionLost) {
            LQLog(kLQLogLevelHttpError, @"<Liquid> Error (%ld) while sending data to server: Server is unreachable", (long)error.code);
            return LQQueueStatusUnreachable;
        } else if(error.code == NSURLErrorUserCancelledAuthentication || error.code == NSURLErrorUserAuthenticationRequired) {
            LQLog(kLQLogLevelHttpError, @"<Liquid> Error (%ld) while sending data to server: Unauthorized (check App Token)", (long)error.code);
            return LQQueueStatusUnauthorized;
        } else {
            LQLog(kLQLogLevelHttpError, @"<Liquid> Error (%ld) while sending data to server: Server error", (long)error.code);
            return LQQueueStatusRejected;
        }
    } else {
        LQLog(kLQLogLevelHttpData, @"<Liquid> Response from server: %@", responseString);
        if(httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
            return LQQueueStatusOk;
        } else {
            LQLog(kLQLogLevelHttpError, @"<Liquid> Error (%ld) while sending data to server: Server error", (long)httpResponse.statusCode);
            return LQQueueStatusRejected;
        }
    }
}

- (NSData *)getDataFromEndpoint:(NSString *)endpoint {
    NSString *fullUrl = [NSString stringWithFormat:@"%@%@", serverUrl, endpoint];
    NSURL *url = [NSURL URLWithString:fullUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:[NSString stringWithFormat:@"Token %@", self.appToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:self.liquidUserAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/vnd.lqd.v1+json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    NSURLResponse *response;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString __unused *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (error) {
        if (error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorCannotConnectToHost || error.code == NSURLErrorNetworkConnectionLost) {
            LQLog(kLQLogLevelHttpError, @"<Liquid> Error (%ld) while getting data from server: Server is unreachable", (long) error.code);
        } else if(error.code == NSURLErrorUserCancelledAuthentication || error.code == NSURLErrorUserAuthenticationRequired) {
            LQLog(kLQLogLevelError, @"<Liquid> Error (%ld) while getting data from server: Unauthorized (check App Token)", (long) error.code);
        } else {
            LQLog(kLQLogLevelHttpError, @"<Liquid> Error (%ld) while getting data from server: Server error", (long) error.code);
        }
        return nil;
    } else {
        LQLog(kLQLogLevelHttpData, @"<Liquid> Response from server: %@", responseString);
        if(httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
            return responseData;
        } else {
            LQLog(kLQLogLevelHttpError, @"<Liquid> Error (%ld) while getting data from server: Server error", (long) httpResponse.statusCode);
            return nil;
        }
    }
}

@end
