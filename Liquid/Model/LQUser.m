//
//  LQUser.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQDevice.h"
#import "LQUser.h"
#import "LQDefaults.h"

@implementation LQUser

#pragma mark - Initializer

-(id)initWithIdentifier:(NSString *)identifier attributes:(NSDictionary *)attributes {
    self = [super init];
    if(self) {
        _identifier = identifier;
        _attributes = attributes;
        if (identifier == nil) {
            _identifier = [LQUser automaticUserIdentifier];
            _autoIdentified = @YES;
        } else {
            _identifier = identifier;
            _autoIdentified = @NO;
        }
        if(_attributes == nil)
            _attributes = [NSDictionary new];
    }
    return self;
}

#pragma mark - JSON

-(NSDictionary *)jsonDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary addEntriesFromDictionary:_attributes];
    [dictionary setObject:_identifier forKey:@"unique_id"];
    [dictionary setObject:_autoIdentified forKey:@"auto_identified"];
    return dictionary;
}

#pragma mark - Attributes

-(void)setAttribute:(id<NSCoding>)attribute forKey:(NSString *)key {
    if (![LQUser assertAttributeType:attribute andKey:key]) return;

    NSMutableDictionary *mutableAttributes = [_attributes mutableCopy];
    [mutableAttributes setObject:attribute forKey:key];
    _attributes = mutableAttributes;
}

-(id)attributeForKey:(NSString *)key {
    return [_attributes objectForKey:key];
}

+(NSString *)automaticUserIdentifier {
    NSString *automaticUserIdentifier = [LQDevice uid];

    if (!automaticUserIdentifier) {
        LQLog(kLQLogLevelError, @"<Liquid> %@ could not get automatic user identifier.", self);
    }
    return automaticUserIdentifier;
}

- (BOOL)isAutoIdentified {
    return [self.autoIdentified isEqual:@YES];
}

#pragma mark - Archive to/from disk

+ (LQUser *)loadFromDisk {
    LQUser *user = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self class] lastUserFile]];
    if (user) {
        NSLog(@"<Liquid> Loaded User %@ %@ from disk", user.identifier, ([user.autoIdentified boolValue] ? @" (auto identified)" : @"(manually identified)"));
    }
    return user;
}

- (BOOL)saveToDisk {
    LQLog(kLQLogLevelData, @"<Liquid> Saving User to disk");
    NSLog(@"<Liquid> Saving User %@ %@ to disk", self.identifier, ([self.autoIdentified boolValue] ? @" (auto identified)" : @"(manually identified)"));
    return [NSKeyedArchiver archiveRootObject:self toFile:[[self class] lastUserFile]];
}

+ (BOOL)destroyLastUser {
    BOOL status = [[NSFileManager defaultManager] removeItemAtPath:[[self class] lastUserFile] error:NULL];
    LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Destroyed cached User");
    NSLog(@"<Liquid> Destroyed cached User");
    return status;
}

+ (NSString *)liquidDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:kLQDirectory];
}

+ (NSString*)lastUserFile {
    NSString *liquidDirectory = [LQUser liquidDirectory];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:liquidDirectory])
        [[NSFileManager defaultManager] createDirectoryAtPath:liquidDirectory
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:&error];
    NSString *liquidFile = [liquidDirectory stringByAppendingPathComponent:@"last_user"];
    LQLog(kLQLogLevelPaths,@"<Liquid> File location %@", liquidFile);
    return liquidFile;
}

#pragma mark - NSCoding & NSCopying

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _identifier = [aDecoder decodeObjectForKey:@"identifier"];
        _attributes = [aDecoder decodeObjectForKey:@"attributes"];
        _autoIdentified = [aDecoder decodeObjectForKey:@"autoIdentified"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_identifier forKey:@"identifier"];
    [aCoder encodeObject:_attributes forKey:@"attributes"];
    [aCoder encodeObject:_autoIdentified forKey:@"autoIdentified"];
}

- (id)copyWithZone:(NSZone *)zone {
    LQUser *user = [[[self class] allocWithZone:zone] init];
    user->_identifier = [_identifier copyWithZone:zone];
    user->_attributes = [_attributes copyWithZone:zone];
    user->_autoIdentified = [_autoIdentified copyWithZone:zone];
    return user;
}

@end
