//
//  NSData+LQData.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 15/05/14.
//  Copyright (c) Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (LQData)

+ (NSData *)randomDataOfLength:(size_t)length;
- (NSString *)hexadecimalString;
+ (id)fromJSON:(NSData *)data;
+ (NSData *)toJSON:(NSDictionary *)object;

@end
