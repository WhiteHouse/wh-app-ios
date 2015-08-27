//
//  BugsnagIosNotifier.m
//  Bugsnag
//
//  Created by Simon Maynard on 8/28/13.
//  Copyright (c) 2013 Simon Maynard. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <sys/utsname.h>


#import "BugsnagIosNotifier.h"

@interface BugsnagIosNotifier ()
@property (readonly) NSString* topMostViewController;
@property (atomic) BOOL inForeground;
@property (atomic) CFAbsoluteTime lastEnteredForeground;
@property (atomic) CFAbsoluteTime appStarted;
@property (atomic) CFAbsoluteTime lastMemoryWarning;
@property (atomic) float batteryLevel;
@property (atomic) BOOL charging;
@property (atomic) NSString *orientation;

- (void)applicationDidBecomeActive:(NSNotification *)notif;
- (void)applicationDidEnterBackground:(NSNotification *)notif;

@end

@implementation BugsnagIosNotifier

- (id) initWithConfiguration:(BugsnagConfiguration*) configuration {
    if((self = [super initWithConfiguration:configuration])) {
        self.notifierName = @"iOS Bugsnag Notifier";
        self.inForeground = YES;
        self.appStarted = self.lastEnteredForeground = CFAbsoluteTimeGetCurrent();
        self.charging = false;
        self.batteryLevel = -1.0;
        self.lastMemoryWarning = 0.0;
        
        [self beforeNotify:^(BugsnagEvent *event) {
            if (event.context == nil && [self topMostViewController]) {
                event.context = [self topMostViewController];
            }
            return YES;
        }];

        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryChanged:) name:UIDeviceBatteryStateDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryChanged:) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lowMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
        [UIDevice currentDevice].batteryMonitoringEnabled = TRUE;
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
    return self;
}

- (NSString *) userUUID {
    // Return the already determined the UUID
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
     
        if (uuid) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setValue:uuid forKey:self.configuration.uuidPath];
            [defaults synchronize];
            return uuid;
        }
    }
    return [super userUUID];
}

- (NSString *) topMostViewController {
    UIViewController *viewController = nil;
    UIViewController *visibleViewController = nil;
    
    if ([[[UIApplication sharedApplication] keyWindow].rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *) [[UIApplication sharedApplication] keyWindow].rootViewController;
        viewController = navigationController.visibleViewController;
    }
    else {
        viewController = [[UIApplication sharedApplication] keyWindow].rootViewController;
    }
    
    int tries = 0;
    
    while (visibleViewController == nil && tries <= 30 && viewController) {
        tries++;
        
        UIViewController *presentedViewController = nil;
        
        if ([viewController respondsToSelector:@selector(presentedViewController)]) {
            presentedViewController = viewController.presentedViewController;
        } else {
            presentedViewController = [viewController performSelector:@selector(modalViewController)];
        }
        
        if (presentedViewController == nil) {
            visibleViewController = viewController;
        } else {
            if ([presentedViewController isKindOfClass:[UINavigationController class]]) {
                UINavigationController *navigationController = (UINavigationController *)presentedViewController;
                viewController = navigationController.visibleViewController;
            } else {
                viewController = presentedViewController;
            }
        }
    }
    
    return NSStringFromClass([visibleViewController class]);
}

- (NSString *) resolution {
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    int scale = [[UIScreen mainScreen] scale];
    return [NSString stringWithFormat:@"%ix%i", (int)screenSize.width * scale, (int)screenSize.height * scale];
}

- (NSString *) density {
    if ([[UIScreen mainScreen] scale] > 1.0) {
        return @"retina";
    } else {
        return @"non-retina";
    }
}

- (BOOL) jailbroken {
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cydia://"]];
}

- (NSString *) locationStatus {
    id CLLocationManager = NSClassFromString(@"CLLocationManager");
    if (CLLocationManager == nil) {
        return nil;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    switch ((int)[CLLocationManager performSelector: @selector(authorizationStatus)]) {
        case 0: // kCLAuthorizationStatusNotDetermined
            return nil;
        case 1: // kCLAuthorizationStatusRestricted
        case 2: // kCLAuthorizationStatusDenied
            return @"disallowed";
        case 3: // kCLAuthorizationStatusAuthorized
            
            if ((BOOL)[CLLocationManager performSelector: @selector(locationServicesEnabled)]) {
                return @"allowed";
            } else {
                return @"disallowed";
            }
            
        default:
            return nil;
    }
#pragma clang diagnostic pop
}

- (void)applicationDidBecomeActive:(NSNotification *)notif {
    self.inForeground = YES;
    self.lastEnteredForeground = CFAbsoluteTimeGetCurrent();
    [self start];
}

- (void)applicationDidEnterBackground:(NSNotification *)notif {
    self.inForeground = NO;
}

- (void)batteryChanged:(NSNotification *)notif {
    self.batteryLevel = [UIDevice currentDevice].batteryLevel;
    self.charging = [UIDevice currentDevice].batteryState == UIDeviceBatteryStateCharging;
}

- (void)orientationChanged:(NSNotification *)notif {
    switch([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            self.orientation = @"portraitupsidedown";
            break;
        case UIDeviceOrientationPortrait:
            self.orientation = @"portrait";
            break;
        case UIDeviceOrientationLandscapeRight:
            self.orientation = @"landscaperight";
            break;
        case UIDeviceOrientationLandscapeLeft:
            self.orientation = @"landscapeleft";
            break;
        case UIDeviceOrientationFaceUp:
            self.orientation = @"faceup";
            break;
        case UIDeviceOrientationFaceDown:
            self.orientation = @"facedown";
            break;
        case UIDeviceOrientationUnknown:
        default:
            self.orientation = @"unknown";
    }
}
- (void)lowMemoryWarning:(NSNotification *)notif {
    self.lastMemoryWarning = CFAbsoluteTimeGetCurrent();
}

- (BugsnagDictionary *) collectDeviceData {
    BugsnagDictionary *deviceData = [super collectDeviceData];
    [deviceData setObject: [self density] forKey: @"screenDensity"];
    [deviceData setObject: [self resolution] forKey: @"screenResolution"];
    if ([self jailbroken]) {
        [deviceData setObject: [NSNumber numberWithBool: [self jailbroken]] forKey: @"jailbroken"];
    }
    return deviceData;
}

- (BugsnagDictionary *) collectAppState {
    BugsnagDictionary *appState = [super collectAppState];
    
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    [appState setObject: [self topMostViewController] forKey:@"activeScreen"];
    [appState setObject: [NSNumber numberWithBool: self.inForeground] forKey:@"inForeground"];
    [appState setObject: [NSNumber numberWithInteger: round(1000.0 * (now - self.lastEnteredForeground))] forKey: @"durationInForeground"];
    [appState setObject: [NSNumber numberWithInteger: round(1000.0 * (now - self.appStarted))] forKey: @"duration"];
    if (self.lastMemoryWarning > 0.0) {
        [appState setObject: [NSNumber numberWithInteger: round(1000.0 * (now - self.lastMemoryWarning))] forKey: @"timeSinceMemoryWarning"];
    }
    
    return appState;
}

- (BugsnagDictionary *) collectDeviceState {
    BugsnagDictionary *deviceState = [super collectDeviceState];

    NSString *locationStatus = [self locationStatus];

    if (locationStatus) {
        [deviceState setObject: [self locationStatus] forKey:@"locationStatus"];
    }
    
    [deviceState setObject: [NSNumber numberWithInteger: round(100.0 * self.batteryLevel)] forKey: @"batteryLevel"];
    [deviceState setObject: [NSNumber numberWithBool: self.charging] forKey: @"charging"];
    if (self.orientation != nil) {
        [deviceState setObject: [self orientation] forKey: @"orientation"];
    }
    
    return deviceState;
}

- (NSString *) osVersion {
    return [[UIDevice currentDevice] systemVersion];
}

@end
