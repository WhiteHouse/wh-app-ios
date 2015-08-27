//
//  BugsnagNotifier.m
//  Bugsnag
//
//  Created by Simon Maynard on 8/28/13.
//  Copyright (c) 2013 Simon Maynard. All rights reserved.
//

#import <execinfo.h>
#import <sys/sysctl.h>
#import <mach/mach.h>

#ifdef TARGET_IPHONE_SIMULATOR
#if TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
#endif
#endif
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "BugsnagNotifier.h"
#import "BugsnagLogger.h"
#import "BugsnagReachability.h"

@interface BugsnagNotifier ()
- (BOOL) transmitPayload:(NSData *)payload toURL:(NSURL*)url;
- (void) addDiagnosticsToEvent:(BugsnagEvent*)event;

@property (readonly) NSString* machine;
@property (readonly) NSString* networkReachability;

@end

@implementation BugsnagNotifier

- (id) initWithConfiguration:(BugsnagConfiguration*) configuration {
    if((self = [super init])) {
        self.configuration = configuration;

        if (self.configuration.userId == nil) self.configuration.userId = self.userUUID;
        [self.configuration.appData addEntriesFromDictionary: [self collectAppData]];
        [self.configuration.deviceData addEntriesFromDictionary: [self collectDeviceData]];

        [self beforeNotify:^(BugsnagEvent *event) {
            [self addDiagnosticsToEvent:event];
            return YES;
        }];

        self.notifierName = @"Bugsnag Objective-C";
#ifdef COCOAPODS_VERSION_MAJOR_Bugsnag
        self.notifierVersion = [NSString stringWithFormat:@"%i.%i.%i", COCOAPODS_VERSION_MAJOR_Bugsnag, COCOAPODS_VERSION_MINOR_Bugsnag, COCOAPODS_VERSION_PATCH_Bugsnag];
#else
        self.notifierVersion = @"3.1.3";
#endif
        self.notifierURL = @"https://github.com/bugsnag/bugsnag-cocoa";
    }
    return self;
}

- (void) start {
    [self performSelectorInBackground:@selector(backgroundStart) withObject:nil];
}

- (void) addDiagnosticsToEvent:(BugsnagEvent*)event {
    event.deviceState = [self collectDeviceState];
    event.appState = [self collectAppState];
}

- (void) notifySignal:(int)signal {
    if([self shouldAutoNotify]) {
        BugsnagEvent *event = [[BugsnagEvent alloc] initWithConfiguration:self.configuration andMetaData: nil];
        [event addSignal:signal];
        event.severity = @"error";
        [self notifyEvent:event inBackground: false];
    }
}

- (void) notifyUncaughtException:(NSException *)exception {
    if ([self shouldAutoNotify]) {
        [self notifyException:exception withData:nil atSeverity: @"error" inBackground:false];
    }
}

- (void) notifyException:(NSException*)exception withData:(NSDictionary*)metaData atSeverity:(NSString*)severity inBackground:(BOOL)inBackground {
    if ([self shouldNotify]) {
        BugsnagEvent *event = [[BugsnagEvent alloc] initWithConfiguration:self.configuration andMetaData:metaData];
        [event addException:exception];

        if (severity == nil || !([severity isEqualToString:@"info"] || [severity isEqualToString:@"warning"] || [severity isEqualToString:@"error"])) {
            severity = @"warning";
        }
        event.severity = severity;
        [self notifyEvent:event inBackground: inBackground];
    }
}

- (BOOL) notifyEvent:(BugsnagEvent*) event inBackground:(BOOL) inBackground{
    @synchronized(self.configuration) {
        for (BugsnagNotifyBlock block in self.configuration.beforeBugsnagNotifyBlocks) {
            BOOL retVal = block(event);
            if (retVal == NO) {
                return NO;
            }
        }
    }
    if (inBackground) {
        [self performSelectorInBackground:@selector(backgroundNotifyEvent:) withObject:event];
    } else {
        [self saveEvent:event];
        [self sendSavedEvents];
    }
    return YES;
}

- (void) backgroundNotifyEvent: (BugsnagEvent*)event {
    @autoreleasepool {
        [self saveEvent:event];
        [self sendSavedEvents];
    }
}

- (void) backgroundStart {
    @autoreleasepool {
        [self sendMetrics];
        [self sendSavedEvents];
    }
}

- (BOOL) shouldNotify {
    return self.configuration.notifyReleaseStages == nil || [self.configuration.notifyReleaseStages containsObject:self.configuration.releaseStage];
}

- (BOOL) shouldAutoNotify {
    return self.configuration.autoNotify && [self shouldNotify];
}

- (NSDictionary*) buildNotifyPayload {
    NSDictionary *notifierDetails = [NSDictionary dictionaryWithObjectsAndKeys:self.notifierName, @"name",
                                                                               self.notifierVersion, @"version",
                                                                               self.notifierURL, @"url", nil];
    NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys:notifierDetails, @"notifier",
                                                                       self.configuration.apiKey, @"apiKey",
                                                                       [NSMutableArray array], @"events", nil];

    return payload;
}

- (void) beforeNotify:(BugsnagNotifyBlock)block {
    @synchronized(self.configuration) {
        [self.configuration.beforeBugsnagNotifyBlocks addObject:[block copy]];
    }
}

- (void) saveEvent:(BugsnagEvent*)event {
    [[NSFileManager defaultManager] createDirectoryAtPath:self.errorPath withIntermediateDirectories:YES attributes:nil error:nil];

    NSDictionary *eventDictionary = [event toDictionary];

    if(![eventDictionary writeToFile:[self generateEventFilename] atomically:YES]) {
        BugsnagLog(@"BUGSNAG: Unable to write event file!");
    }
}

- (NSArray *) savedEvents {
	NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.errorPath error:nil];
	NSMutableArray *savedReports = [NSMutableArray arrayWithCapacity:[directoryContents count]];
	for (NSString *file in directoryContents) {
		if ([[file pathExtension] isEqualToString:@"bugsnag"]) {
			NSString *crashPath = [self.errorPath stringByAppendingPathComponent:file];
			[savedReports addObject:crashPath];
		}
	}
	return savedReports;
}

- (void) sendSavedEvents {
    @synchronized(self) {
        @try {
            NSArray *savedEvents = [self savedEvents];
            for ( NSString *file in savedEvents ) {
                NSMutableDictionary *event = [NSMutableDictionary dictionaryWithContentsOfFile:file];
                if (event == nil || [self sendEvent:event]) {
                    [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
                }
            }
        }
        @catch (NSException *exception) {
            BugsnagLog(@"Exception while sending bugsnag events: %@", exception);
        }
    }
}

- (BOOL) sendEvent:(NSDictionary*)event {
    if (event == nil) {
        return NO;
    }

    NSDictionary *notifyPayload = [self buildNotifyPayload];
    [[notifyPayload objectForKey:@"events"] addObject:event];

    NSData *jsonPayload = [NSJSONSerialization dataWithJSONObject:notifyPayload options:0 error:nil];

    return [self transmitPayload:jsonPayload toURL:self.configuration.notifyURL];
}

- (BOOL) sendMetrics {
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    [payload setObject:self.configuration.apiKey forKey:@"apiKey"];
    [payload setObject:self.configuration.appData.data forKey:@"app"];
    [payload setObject:self.configuration.deviceData.data forKey:@"device"];
    [payload setObject:self.configuration.userData.data forKey:@"user"];

    NSData *jsonPayload = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];

    return [self transmitPayload:jsonPayload toURL:self.configuration.metricsURL];
}

- (NSString*) errorPath {
    @synchronized(_errorPath) {
        if(_errorPath) return _errorPath;
        NSArray *folders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *filename = [folders count] == 0 ? NSTemporaryDirectory() : [folders objectAtIndex:0];
        _errorPath = [filename stringByAppendingPathComponent:@"bugsnag"];
        return _errorPath;
    }
}

- (NSString *) generateEventFilename {
    return [[self.errorPath stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] stringByAppendingPathExtension:@"bugsnag"];
}

- (BOOL) transmitPayload:(NSData *)payload toURL:(NSURL*)url {
    if(payload){
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:payload];
        [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];

        NSURLResponse* response = nil;
        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];

        NSInteger statusCode = [((NSHTTPURLResponse *)response) statusCode];
        if (statusCode != 200) {
            BugsnagLog(@"Bad response from bugsnag received: %ld.", (long)statusCode);
        } else {
            return YES;
        }
    }
    return NO;
}

- (NSString *) userUUID {
    @synchronized(_uuid) {
        // Return the already determined the UUID
        if(_uuid) return _uuid;

        // Try to read UUID from NSUserDefaults
        _uuid = [[NSUserDefaults standardUserDefaults] stringForKey:self.configuration.uuidPath];
        if(_uuid) return _uuid;

        // Generate a fresh UUID
        CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
        _uuid = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
        CFRelease(uuid);

        // Try to save the UUID to the NSUserDefaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:_uuid forKey:self.configuration.uuidPath];
        [defaults synchronize];
        return _uuid;
    }
}

- (NSString *) machine {
    NSString *machine = nil;

    int mib[] = { CTL_HW, HW_MACHINE };
    const size_t mibLen = sizeof(mib)/sizeof(*mib);

    // Get length of requested string
    size_t machineCStringLenEstimate;
    if (0 == sysctl(mib, mibLen, NULL, &machineCStringLenEstimate, NULL, 0)) {
        char *machineCString = malloc(machineCStringLenEstimate);
        if (NULL != machineCString) {
            // Copy value to buffer
            size_t machineCStringLen;
            if (0 == sysctl(mib, mibLen, machineCString, &machineCStringLen, NULL, 0)
                && machineCStringLen <= machineCStringLenEstimate) {
                machine = [[NSString alloc] initWithCString:machineCString encoding:NSUTF8StringEncoding];
            }
            free(machineCString);
        }
    }

    return machine;
}

- (NSString *) networkReachability {

    BugsnagReachability *reachability = [BugsnagReachability reachabilityForInternetConnection];
    [reachability startNotifier];

    NSString *returnValue = @"none";
    if ([reachability isReachableViaWiFi]) {
         returnValue = @"wifi";
    } else if ([reachability isReachableViaWWAN]) {
        returnValue = @"cellular";
    }

    [reachability stopNotifier];

    return returnValue;
}

- (BugsnagDictionary *) collectAppData {
    NSBundle* bundle = [NSBundle mainBundle];
    NSString* version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString* bundleVersion = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString* name = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];

    BugsnagDictionary *appData = [[BugsnagDictionary alloc] init];

    if (version != nil) {
        [appData setObject: version forKey: @"version"];
    } else if (bundleVersion != nil) {
        [appData setObject: bundleVersion forKey: @"version"];
    }
    if (bundleVersion != nil) [appData setObject: bundleVersion forKey: @"bundleVersion"];
    if (name != nil) [appData setObject: name forKey:@"name"];
    [appData setObject: [bundle bundleIdentifier] forKey: @"id"];

    return appData;
}

- (BugsnagDictionary *) collectDeviceData {

    BugsnagDictionary *deviceData = [[BugsnagDictionary alloc] init];
    [deviceData setObject: [self userUUID] forKey: @"id"];
    [deviceData setObject: @"Apple" forKey: @"manufacturer"];
    [deviceData setObject: [self machine] forKey: @"model"];

    uint64_t totalMemory = 0;
    size_t size = sizeof(totalMemory);
    if (!sysctlbyname("hw.memsize", &totalMemory, &size, NULL, 0)) {
        [deviceData setObject:[NSNumber numberWithLongLong: totalMemory] forKey: @"totalMemory"];
    }

    // Get a path on the main disk (lots of stack-overflow answers suggest using @"/", but that doesn't work).
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *atDict = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error:NULL];
    if (atDict) {
        [deviceData setObject: [atDict objectForKey:NSFileSystemSize] forKey:@"diskSize"];
    }

    [deviceData setObject: [[NSLocale currentLocale] localeIdentifier] forKey:@"locale"];
    [deviceData setObject: [self osVersion] forKey:@"osVersion"];
    [deviceData setObject: [self osName] forKey:@"osName"];

    return deviceData;
}

- (BugsnagDictionary *) collectAppState {
    BugsnagDictionary *appState = [[BugsnagDictionary alloc] init];

    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                    TASK_BASIC_INFO,
                                    (task_info_t)&info,
                                    &size);

    if ( kerr == KERN_SUCCESS ) {
       [appState setObject:[NSNumber numberWithInteger:info.resident_size] forKey:@"memoryUsage"];
    }

    return appState;
}

- (BugsnagDictionary *) collectDeviceState {
    BugsnagDictionary *deviceState = [[BugsnagDictionary alloc] init];

    uint64_t pageSize = 0;
    uint64_t pagesFree = 0;
    size_t sysCtlSize = sizeof(uint64_t);
    if (!sysctlbyname("vm.page_free_count", &pagesFree, &sysCtlSize, NULL, 0)) {
        if (!sysctlbyname("hw.pagesize", &pageSize, &sysCtlSize, NULL, 0)) {
            [deviceState setObject: [NSNumber numberWithLongLong:pagesFree*pageSize] forKey:@"freeMemory"];
        }
    }

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *atDict = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error:NULL];
    if (atDict) {
        [deviceState setObject: [atDict objectForKey:NSFileSystemFreeSize] forKey:@"freeDisk"];
    }

    [deviceState setObject: self.networkReachability forKey: @"networkAccess"];

    return deviceState;
}

- (NSString *) osVersion {
#ifdef TARGET_IPHONE_SIMULATOR
#if TARGET_IPHONE_SIMULATOR
	return [[UIDevice currentDevice] systemVersion];
#else
    return [[NSProcessInfo processInfo] operatingSystemVersionString];
#endif
#else
	return [[NSProcessInfo processInfo] operatingSystemVersionString];
#endif
}

- (NSString *) osName {
#if TARGET_OS_IPHONE
    return @"iOS";
#else
    // TODO... This doesn't seem to be exposed anywhere.
    // NSProcessInfo-operatingSystemName == "NSMachOperatingSystem"
    // sysctlbyname('kern.osrelease') == "Darwin"
    return @"OS X";
#endif
}


@end
