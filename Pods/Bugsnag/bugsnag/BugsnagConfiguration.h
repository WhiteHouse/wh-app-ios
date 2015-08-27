//
//  BugsnagConfiguration.h
//  bugsnag
//
//  Created by Simon Maynard on 8/28/13.
//  Copyright (c) 2013 Simon Maynard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BugsnagMetaData.h"
#import "BugsnagDictionary.h"

#define USER_TAB_NAME @"User"

@interface BugsnagConfiguration : NSObject

-(void) setUser: (NSString*) userId withName: (NSString*) userName andEmail: (NSString*) userEmail;

@property (atomic, copy) NSString *apiKey;

@property (atomic, copy) NSString *userId;
@property (atomic, copy) NSString *userName;
@property (atomic, copy) NSString *userEmail;

@property (atomic, copy) NSString *releaseStage;
@property (atomic, copy) NSString *osVersion;
@property (atomic, copy) NSString *appVersion;
@property (atomic, copy) NSString *context;

@property (atomic, strong) BugsnagMetaData *metaData;
@property (atomic, strong) BugsnagDictionary *appData;
@property (atomic, strong) BugsnagDictionary *deviceData;
@property (atomic, strong) BugsnagDictionary *userData;

@property (atomic) BOOL enableSSL;
@property (atomic) BOOL autoNotify;
@property (atomic) BOOL collectMAU;
@property (atomic, copy) NSArray *notifyReleaseStages;

@property (readonly) NSURL *metricsURL;
@property (readonly) NSURL *notifyURL;

@property (atomic, copy) NSString *notifyEndpoint;
@property (atomic, copy) NSString *uuidPath;
@property (atomic, strong) NSMutableArray *beforeBugsnagNotifyBlocks;

@end