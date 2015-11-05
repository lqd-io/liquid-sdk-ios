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
#import "NSString+LQString.h"
#import "LQStorage.h"

@interface LQUser()

@property(atomic, strong) NSString *identifier;
@property(atomic, strong) NSNumber *identified;

@end

@implementation LQUser {
    NSDictionary *_attributes;
}

#pragma mark - Initializer

- (id)initWithIdentifier:(NSString *)identifier attributes:(NSDictionary *)attributes {
    self = [super init];
    if(self) {
        _identifier = identifier;
        _attributes = attributes;
        if (identifier == nil) {
            _identifier = [LQUser generateRandomUserIdentifier];
            _identified = @NO;
        } else {
            _identifier = identifier;
            _identified = @YES;
        }
        if(_attributes == nil)
            _attributes = [NSDictionary new];
    }
    return self;
}

#pragma mark - JSON

- (NSDictionary *)jsonDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary addEntriesFromDictionary:self.attributes];
    [dictionary setObject:self.identifier forKey:@"unique_id"];
    [dictionary setObject:self.identified forKey:@"identified"];
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

#pragma mark - Attributes

- (void)setAttribute:(id <NSCoding>)attribute forKey:(NSString *)key {
    if (![LQUser assertAttributeType:attribute andKey:key]) return;
    NSMutableDictionary *mutableAttributes = [self.attributes mutableCopy];
    [mutableAttributes setObject:attribute forKey:key];
    self.attributes = [NSDictionary dictionaryWithDictionary:mutableAttributes];
}

- (id)attributeForKey:(NSString *)key {
    return [self.attributes objectForKey:key];
}

- (void)resetAttributes {
    self.attributes = [NSDictionary new];
}

+ (NSDictionary *)reservedAttributes {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @YES, @"_id",
            @YES, @"id",
            @YES, @"unique_id",
            @YES, @"identified",
            @YES, @"aliased",
            @YES, @"aliased_unique_id",
            @YES, @"created_at",
            @YES, @"updated_at", nil];
}

+ (NSString *)generateRandomUserIdentifier {
    return [NSString generateRandomUUIDAppendingTimestamp:YES];
}

- (BOOL)isIdentified {
    return !![self.identified boolValue];
}

- (BOOL)isAnonymous {
    return ![self isIdentified];
}

#pragma mark - Archive to/from disk

- (BOOL)archiveUserForToken:(NSString *)apiToken {
    LQLog(kLQLogLevelData, @"<Liquid> Saving User %@ %@ to disk, for token %@", self.identifier, (![self.identified boolValue] ? @" (anonymous)" : @"(identified)"), apiToken);
    return [NSKeyedArchiver archiveRootObject:self toFile:[LQUser userFileForToken:apiToken]];
}

+ (LQUser *)unarchiveUserForToken:(NSString *)apiToken {
    NSString *token = apiToken;
    NSString *filePath = [LQUser userFileForToken:token];
    LQUser *user = nil;
    @try {
        id object = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        user = [object isKindOfClass:[LQUser class]] ? object : nil;
    }
    @catch (NSException *exception) {
        LQLog(kLQLogLevelError, @"<Liquid> %@: Found invalid Liquid Package on cache. Destroying it...", [exception name]);
        [LQStorage deleteFileIfExists:filePath error:nil];
    }
    if (user) {
        LQLog(kLQLogLevelData, @"<Liquid> Loaded User %@ %@ from disk, for token %@", user.identifier, (![user.identified boolValue] ? @" (anonymous)" : @"(identified)"), token);
    }
    return user;
}

+ (NSString*)userFileForToken:(NSString *)apiToken {
    return [LQStorage filePathWithExtension:@"last_user" forToken:apiToken];
}

+ (void)deleteUserFileForToken:(NSString *)apiToken {
    NSString *token = apiToken;
    NSString *filePath = [LQUser userFileForToken:token];
    LQLog(kLQLogLevelInfo, @"<Liquid> Deleting cached User, for token %@", token);
    NSError *error;
    [LQStorage deleteFileIfExists:filePath error:&error];
    if (error) {
        LQLog(kLQLogLevelError, @"<Liquid> Error deleting cached User, for token %@", apiToken);
    }
}

#pragma mark - NSCoding & NSCopying

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.identifier = [aDecoder decodeObjectForKey:@"identifier"];
        self.attributes = [aDecoder decodeObjectForKey:@"attributes"];
        self.identified = [aDecoder decodeObjectForKey:@"identified"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.identifier forKey:@"identifier"];
    [aCoder encodeObject:self.attributes forKey:@"attributes"];
    [aCoder encodeObject:self.identified forKey:@"identified"];
}

@end
