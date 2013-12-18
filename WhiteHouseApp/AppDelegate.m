/*
 * This project constitutes a work of the United States Government and is
 * not subject to domestic copyright protection under 17 USC § 105.
 * 
 * However, because the project utilizes code licensed from contributors
 * and other third parties, it therefore is licensed under the MIT
 * License.  http://opensource.org/licenses/mit-license.php.  Under that
 * license, permission is granted free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the conditions that any appropriate copyright notices and this
 * permission notice are included in all copies or substantial portions
 * of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

//
//  AppDelegate.m
//  WhiteHouseApp
//
//

#import "AppDelegate.h"

#import "WHRootMenuViewController.h"
#import "WHFeedCollection.h"
#import "WHBlogViewController.h"
#import "WHLiveFeedViewController.h"
#import "WHReaderViewController.h"
#import "WHPhotoGalleryViewController.h"
#import "WHFavoritesViewController.h"
#import "WHVideoViewController.h"
#import "WHRemoteFile.h"
#import "UATagUtils.h"
#import "UAPush.h"


@interface AppDelegate ()
@property (nonatomic, strong) WHRevealViewController *reveal;
@property (nonatomic, strong) WHRootMenuViewController *menu;
@property (nonatomic, strong) WHFeedViewController *liveSectionViewController;
@property (nonatomic, strong) WHLiveController *liveController;
@property (nonatomic, strong) NSDictionary *pendingNotification;
- (void)initFacebook;
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error;
- (NSDictionary*)parseURLParams:(NSString *)query;
@end


@implementation AppDelegate

@synthesize window = _window;
@synthesize reveal = _reveal;
@synthesize menu;
@synthesize liveSectionViewController = _liveViewController;
@synthesize liveController;
@synthesize liveBarController;
@synthesize pendingNotification;

- (void)configureAppearance
{
    [[UINavigationBar appearance] setTintColor:[WHStyle controlTintColor]];
    [[UIToolbar appearance] setTintColor:[WHStyle controlTintColor]];
    
    UIImage *barImage = [UIImage imageNamed:@"bar-background"];
    [[UINavigationBar appearance] setBackgroundImage:barImage forBarMetrics:UIBarMetricsDefault];
    [[UIToolbar appearance] setBackgroundImage:barImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    
    UIImage *barImageLandscape = [UIImage imageNamed:@"bar-background-landscape"];
    [[UINavigationBar appearance] setBackgroundImage:barImageLandscape forBarMetrics:UIBarMetricsLandscapePhone];
}


/**
 * Wrap viewController in a navigation controller and a WHMenuItem
 */
- (WHMenuItem *)createMenuItem:(UIViewController *)viewController
{
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[WHStyle headingFontWithSize:22.0], UITextAttributeFont, nil];
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(revealToggle:)];
    viewController.navigationItem.leftBarButtonItem = menuButton;
    return [[WHMenuItem alloc] initWithTitle:viewController.title icon:nil viewController:navController];
}


/**
 * Try to parse JSON data. Returns nil and logs errors if parsing fails.
 */
+ (NSDictionary *)parseJSONData:(NSData *)data
{
    if (!data) {
        return nil;
    }
    
    NSError *parsingError;
    id result = [NSJSONSerialization JSONObjectWithData:data
                                                options:0
                                                  error:&parsingError];
    
    if (!result) {
        NSLog(@"Error parsing feed config: %@", parsingError.localizedDescription);
    }
    
    return result;
}


- (NSDictionary *)feedConfig
{
    NSURL *configURL = [NSURL URLWithString:AppConfig(@"FeedConfigURL")];
    WHRemoteFile *feedConfigFile = [[WHRemoteFile alloc] initWithBundleResource:@"config" ofType:@"json" remoteURL:configURL];
    [feedConfigFile updateWithValidator:^BOOL(NSData *remoteData) {
        return [[self class] parseJSONData:remoteData] != nil;
    }];
    
    return [[self class] parseJSONData:[feedConfigFile data]];
}


- (WHRootMenuViewController *)loadMenu
{
    WHRootMenuViewController *menuController = [[WHRootMenuViewController alloc] initWithNibName:nil bundle:nil];
    self.menu = menuController;
    
    NSMutableArray *items = [NSMutableArray array];
    
    NSDictionary *feedConfig = [self feedConfig];
    
    NSArray *menuItemsConfig = [feedConfig objectForKey:@"feeds"];
    
    int currentIndex = 0;
    for (NSDictionary *itemConfig in menuItemsConfig) {
        NSString *title = [itemConfig objectForKey:@"title"];
        NSURL *feedURL = [NSURL URLWithString:[itemConfig objectForKey:@"feed-url"]];
        NSString *viewType = [itemConfig objectForKey:@"view-type"];
        
        WHFeed *feed = nil;
        if (feedURL) {
            feed = [[WHFeedCollection sharedFeedCollection] feedForURL:feedURL];
            feed.title = title;
            // don't store live feeds
            feed.isDatabaseBacked = ![viewType isEqualToString:@"live"];
        }
        
        UIViewController *viewController = nil;
        
        if ([viewType isEqualToString:@"article-list"]) {
            if (NIIsPad()) {
                WHReaderViewController *reader = [[WHReaderViewController alloc] initWithFeed:feed];
                NSNumber *showAuthor = [itemConfig objectForKey:@"show-author"];
                reader.showAuthor = [showAuthor boolValue];
                viewController = reader;
            } else {
                viewController = [[WHBlogViewController alloc] initWithFeed:feed];
            }
        } else if ([viewType isEqualToString:@"photo-gallery"]) {
            viewController = [[WHPhotoGalleryViewController alloc] initWithFeed:feed];
        } else if ([viewType isEqualToString:@"video-gallery"]) {
            if (NIIsPad()) {
                WHReaderViewController *iPadVideo = [[WHReaderViewController alloc] initWithFeed:feed];
                iPadVideo.pressToShare = YES;
                viewController = iPadVideo;
                
            } else {
                viewController = [[WHVideoViewController alloc] initWithFeed:feed];
            }
        } else if ([viewType isEqualToString:@"live"]) {
            self.liveSectionViewController = [[WHLiveFeedViewController alloc] initWithFeed:feed];
            viewController = self.liveSectionViewController;
            liveSectionMenuIndex = currentIndex;
            
            NSInteger freq = [AppConfig(@"LiveFeedUpdateFrequency") integerValue];
            self.liveController = [[WHLiveController alloc] initWithFeed:feed updateFrequency:freq];
            self.liveBarController = [[WHLiveBarController alloc] init];
        }
        
        viewController.title = title;
        [items addObject:[self createMenuItem:viewController]];
        currentIndex++;
    }
    
    UIViewController *favoritesViewController = [[WHFavoritesViewController alloc] initWithNibName:nil bundle:nil];
    favoritesViewController.title = NSLocalizedString(@"FavoritesMenuItemTitle", @"Title displayed in the menu for Favorites section");
    [items addObject:[self createMenuItem:favoritesViewController]];
    
    menuController.menuItems = items;
    
    return menuController;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [self configureAppearance];
    
    // configure Google Analytics
    NSString *accountID = AppConfig(@"GANAccountID");
    [GAI sharedInstance].dispatchInterval = 30;
    
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:accountID];
    tracker.anonymize = YES;
    [tracker sendView:@"/LAUNCH"];
    
    // check for cached facebook session
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        [self initFacebook];
    }
    
    self.menu = [self loadMenu];
    UIViewController *defaultViewController = [[self.menu.menuItems objectAtIndex:0] viewController];
    self.reveal = [[WHRevealViewController alloc] initWithMenuViewController:self.menu contentViewController:defaultViewController];
    self.window.rootViewController = self.reveal;
    
    [self.window makeKeyAndVisible];
    
    // select and display the first item in the menu
    self.menu.selectedMenuItemIndex = 0;
    
    // notifications MUST be handled after the menu is loaded
    NSDictionary *note = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (note) {
        [self handleNotification:note];
    }
    
    // start updating live events
    [self.liveController startUpdating];
    [self initAirship:application];
    
#ifdef DEBUG
    // uncomment to test notifications
    // [self performSelector:@selector(testNotification) withObject:nil afterDelay:5];
#endif
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppEvents activateApp];
    [FBSession.activeSession handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [FBSession.activeSession close];
}

- (void)initAirship:(UIApplication *)application
{
    [UAirship takeOff];
    
    // Register for notifications    
    [UAPush shared].notificationTypes = (UIRemoteNotificationTypeBadge |
                                         UIRemoteNotificationTypeSound |
                                         UIRemoteNotificationTypeAlert);
}

#pragma mark Push notification handling


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Updates the device token and registers the token with UA
    DebugLog(@"Got registration data: %@", deviceToken);
    
    // use a basic set of Urban Airship tags
    NSArray *baseTags = [UATagUtils createTags:(UATagTypeTimeZoneAbbreviation |
                                                UATagTypeLanguage |
                                                UATagTypeCountry |
                                                UATagTypeDeviceType)];
    // specify the new version of the app, so we can send appropriate notifications
    NSArray *tags = [baseTags arrayByAddingObject:@"app_v2"];
    [UAPush shared].tags = tags;
    [[UAPush shared] registerDeviceToken:deviceToken];
}


- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Failed to register: %@", error.localizedDescription);
}


#ifdef DEBUG
- (void)testNotification
{
    NSDictionary *aps = [NSDictionary dictionaryWithObjectsAndKeys:@"test DEBUG", @"alert", nil];
    NSDictionary *custom = [NSDictionary dictionaryWithObjectsAndKeys:@"http://google.com", @"video-url", nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:aps, @"aps", custom, @"wh", nil];
    [self application:[UIApplication sharedApplication] didReceiveRemoteNotification:userInfo];
}
#endif


+ (id)customDataForNotification:(NSDictionary *)userInfo
{
    return [userInfo objectForKey:@"wh"];
}


- (void)handleNotification:(NSDictionary *)userInfo
{
    NSDictionary *custom = [[self class] customDataForNotification:userInfo];
    NSString *notificationURLString = [custom objectForKey:@"video-url"];
    if ([[custom objectForKey:@"action"] isEqualToString:@"go-live"] || notificationURLString != nil) {
        self.menu.selectedMenuItemIndex = liveSectionMenuIndex;
        
        if (notificationURLString) {
            WHFeedItem *dummyItem = [[WHFeedItem alloc] init];
            dummyItem.enclosureURL = [NSURL URLWithString:notificationURLString];
            [self.liveSectionViewController displayFeedItem:dummyItem];
        }
    }
}


- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    // just pass this on to the remote notification handling routine... they serve the same purpose
    [self application:application didReceiveRemoteNotification:notification.userInfo];
}


/*
 * This method is called when the app is running in an active OR background state. So we need to
 * present the user with a dialog if the app is active. Otherwise, the app is being brought from 
 * the background in response to tapping on the notification.
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    UIApplicationState state = [application applicationState];
    
    if (state == UIApplicationStateActive) {
        // store the userInfo dictionary so we can respond to it when the user responds to the alert
        self.pendingNotification = userInfo;
        
        // the aps.alert value is the only text displayed (the alert has no title)
        NSString *message = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"PushNotificationDismissButton", @"A button which dismisses a push notification alert popup")
                                              otherButtonTitles:nil];

        // if there's a video URL or action, the alert should have a "View" button
        NSDictionary *custom = [[self class] customDataForNotification:userInfo];
        if ([custom objectForKey:@"video-url"] || [custom objectForKey:@"action"])
        {
            [alert addButtonWithTitle:NSLocalizedString(@"PushNotificationViewButton", @"A button to view the content of a push notification")];
        }
        
        [alert show];
        
    } else {
        [self handleNotification:userInfo];
    }
}


#pragma mark Alert view handling


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (self.pendingNotification && buttonIndex != alertView.cancelButtonIndex) {
        [self handleNotification:self.pendingNotification];
        self.pendingNotification = nil;
    }
}


#pragma mark - reveal methods

- (void)revealToggle:(id)sender
{
    [self.reveal setMenuVisible:YES wantsFullWidth:NO];
}

//#pragma mark - Facebook methods

- (BOOL)application:(UIApplication *)application 
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication 
         annotation:(id)annotation {
    return [FBSession.activeSession handleOpenURL:url]; 
}

- (void)initFacebook
{
    [FBSession openActiveSessionWithReadPermissions:nil
                                       allowLoginUI:NO
                                  completionHandler:
                                       ^(FBSession *session, 
                                         FBSessionState state, NSError *error) {
                    [self sessionStateChanged:session state:state error:error];
    }];
}

- (void)sessionStateChanged:(FBSession *)session 
                      state:(FBSessionState)state
                      error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen:
            NSLog(@"User has logged in to Facebook (or cached token was available)");
            break;
        case FBSessionStateOpenTokenExtended:
            NSLog(@"Facebook token has been extended");
            break;
        case FBSessionStateClosedLoginFailed:
            NSLog(@"Facebook login attempt failed");
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        case FBSessionStateClosed:
            NSLog(@"Facebook session was closed");
            break;
        default:
            break;
    }
    
    if (error) {
        NSLog(@"Facebook session state change error: %@", error.localizedDescription);
    }
}

- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val = [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}

- (void)shareOnFacebook:(WHFeedItem *)item
{
    if (!FBSession.activeSession.isOpen) {
        [self initFacebook];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:[item.link absoluteString], @"link", item.title, @"name", nil];
    
    // look for pictures in the post
    WHMediaElement *media = [item bestContentForWidth:0];
    if (media == nil) {
        media = [item bestThumbnailForWidth:0];
    }
    if (media) {
        [params setObject:[media.URL absoluteString] forKey:@"picture"];
    }
    
    [FBWebDialogs presentFeedDialogModallyWithSession:nil 
                                           parameters:params 
                                              handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                  if (error) {
                                                      // Error launching the dialog or publishing story
                                                      NSLog(@"Error publishing Facebook story: %@", error.localizedDescription);
                                                      return;
                                                  }
                                                  if (result == FBWebDialogResultDialogNotCompleted) {
                                                      // User clicked the "x" icon
                                                      NSLog(@"User canceled Facebook story publishing");
                                                      return;
                                                  }
                                                  NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                                                  if (![urlParams valueForKey:@"post_id"]) {
                                                      // User clicked the Cancel button
                                                      NSLog(@"User canceled Facebook story publishing");
                                                      return;
                                                  }
                                                  NSLog(@"Posted Facebook story, id: %@", [urlParams valueForKey:@"post_id"]);
    }];
}

@end
