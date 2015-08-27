//
//  BugsnagEvent.h
//  bugsnag
//
//  Created by Simon Maynard on 8/28/13.
//  Copyright (c) 2013 Simon Maynard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BugsnagConfiguration.h"
#import "BugsnagMetaData.h"

@interface BugsnagEvent : NSObject

- (id) initWithConfiguration:(BugsnagConfiguration *)configuration andMetaData:(NSDictionary*)metaData;

- (void) addSignal:(int) signal;
- (void) addException:(NSException*)exception;

- (NSDictionary *) toDictionary;

- (NSDictionary *) loadedImages;
- (NSArray *) getStackTraceWithException:(NSException*) exception;

- (void) setUserAttribute:(NSString*)attributeName withValue:(id)value;
- (void) clearUser;
- (void) addAttribute:(NSString*)attributeName withValue:(id)value toTabWithName:(NSString*)tabName;
- (void) clearTabWithName:(NSString*)tabName;

@property (atomic, copy) NSString *context;
@property (atomic, strong) BugsnagMetaData *metaData;
@property (atomic, strong) BugsnagDictionary *deviceState;
@property (atomic, strong) BugsnagDictionary *appState;
@property (atomic, strong) NSString *severity;

@end
