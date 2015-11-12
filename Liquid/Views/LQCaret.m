//
//  LQCaret.m
//  Liquid
//
//  Created by Miguel M. Almeida on 10/11/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQCaret.h"

@interface LQCaret ()

@property (nonatomic, assign) CGPathRef caretPath;

@end

@implementation LQCaret

@synthesize caretPath = _caretPath;
@synthesize strokeColor = _strokeColor;

#pragma mark - Initializers

- (instancetype)initWithFrame:(CGRect)frame strokeColor:(UIColor *)strokeColor {
    self = [self initWithFrame:frame];
    if (self) {
        self.strokeColor = strokeColor;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (UIColor *)strokeColor {
    if (!_strokeColor) {
        _strokeColor = [UIColor blackColor];
    }
    return _strokeColor;
}

#pragma mark - Draw Caret

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    self.caretPath = [self caretPathWithRect:rect];

    CGContextSetStrokeColor(context, CGColorGetComponents(self.strokeColor.CGColor));
    CGContextSetFillColor(context, CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    CGContextAddPath(context, self.caretPath);
    CGContextDrawPath(context, kCGPathStroke);
}

- (CGMutablePathRef)caretPathWithRect:(CGRect)rect {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPoint center = CGPointMake(rect.size.width / 2, rect.size.height / 2);
    CGPathMoveToPoint(path, NULL, 0, 0);
    CGPathAddLineToPoint(path, NULL, center.x, center.y);
    CGPathAddLineToPoint(path, NULL, 0, rect.size.height);
    //CGPathCloseSubpath(path);
    return path;
}

#pragma mark - User interaction

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return NO;
}

@end
