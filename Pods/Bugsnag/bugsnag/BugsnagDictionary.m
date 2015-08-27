//
//  BugsnagDictionary.m
//  Bugsnag
//
//  Created by Conrad Irwin on 10/31/13.
//  Copyright (c) 2013 Simon Maynard. All rights reserved.
//

#import "BugsnagDictionary.h"

@implementation BugsnagDictionary

- (BugsnagDictionary*) init {
    return [self initWithMutableDictionary: [[NSMutableDictionary alloc] init]];
}

- (BugsnagDictionary*) initWithMutableDictionary:(NSMutableDictionary *)dictionary {
    if (self = [super init]) {
        self.data = dictionary;
    }
    return self;
}

- (void) setObject:(id)value forKey:(NSString *)key {
    if (!key) {
        return;
    }
    @synchronized(self) {
        if (value) {
            [self.data setObject: value forKey: key];
        } else {
            [self.data removeObjectForKey: key];
        }
    }
}

- (void) addEntriesFromDictionary:(BugsnagDictionary *)dictionary {
    @synchronized(self) {
        [self.data addEntriesFromDictionary:dictionary.data];
    }
}

- (id) objectForKey:(NSString *)key {
    @synchronized(self) {
        if (!key) {
            return nil;
        }
        return [self.data objectForKey:key];
    }
}
@end
