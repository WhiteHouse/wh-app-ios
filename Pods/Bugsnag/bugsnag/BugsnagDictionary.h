//
//  BugsnagDictionary.h
//  Bugsnag
//
//  Created by Conrad Irwin on 10/31/13.
//  Copyright (c) 2013 Simon Maynard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BugsnagDictionary : NSObject
@property (atomic,strong) NSMutableDictionary *data;
- (BugsnagDictionary *) initWithMutableDictionary:(NSMutableDictionary*)dictionary;
- (void) setObject:(id)value forKey:(NSString *)key;
- (void) addEntriesFromDictionary: (BugsnagDictionary *)dictionary;
- (id) objectForKey:(NSString *)key;
@end
