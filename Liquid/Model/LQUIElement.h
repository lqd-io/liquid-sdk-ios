//
//  LQUIElement.h
//  Liquid
//
//  Created by Miguel M. Almeida on 10/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LQUIElement : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSString *eventName;
@property (nonatomic, strong, readonly) NSDictionary *jsonDictionary;

- (instancetype)initFromUIView:(UIView *)view evetName:(NSString *)eventName;
- (instancetype)initFromUIView:(UIView *)view;
- (instancetype)initFromDictionary:(NSDictionary *)dict;
- (BOOL)matchesUIView:(UIView *)view;

@end
