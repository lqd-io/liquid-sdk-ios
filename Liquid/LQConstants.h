//
//  LQConstants.h
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/28/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

// Customizable options
#define kLQDefaultSessionTimeout @30 //seconds
#define kLQQueueSizeLimit 500 // datapoints
#ifdef DEBUG
#    define kLQDefaultFlushInterval @5 //seconds
#else
#    define kLQDefaultFlushInterval @10 //seconds
#endif
#define kLQMaxNumberOfTries 40
#define kLQDefaultFlushOnBackground YES
#define kLQDirectory kLQBundle
#define kLQValuesFileName @"LiquidVariables"
#define kLQSendBundleVariablesInDevelopmentMode YES
#define kLQDefaultSessionMaxLimit @7200 // seconds (if for some reason the applicationWillResignActive: code doesn't run)

#define kLQLogLevel 3

// Liquid internal constants
#define kLQVersion @"0.3.2"
#define kLQBundle @"com.liquid"
#define kLQServerUrl @"http://api.lqd.io/collect/"
#define LQDidReceiveValues @"com.liquid.Notifications:LQDidReceiveValues"
#define LQDidLoadValues @"com.liquid.Notifications:DidLoadValues"
#define kLQLogLevelPaths       7
#define kLQLogLevelHttp        6
#define kLQLogLevelData        5
#define kLQLogLevelInfoVerbose 4
#define kLQLogLevelInfo        3
#define kLQLogLevelWarning     2
#define kLQLogLevelError       1

#ifdef DEBUG
#   define LQLog(level,...) if(level<=kLQLogLevel) NSLog(__VA_ARGS__)
#else
#   define LQLog(...)
#endif
