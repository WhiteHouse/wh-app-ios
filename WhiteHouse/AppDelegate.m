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
//  WhiteHouse
//


#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "LiveViewController.h"
#import "MainViewController.h"
#import "SidebarViewController.h"
#import "Bugsnag.h"
#import "GAI.h"
#import "AFHTTPRequestOperation.h"
#import "WHFeedItem.h"
#import "FavoritesViewController.h"
#import "DOMParser.h"


@interface AppDelegate ()<SWRevealViewControllerDelegate>

@end

@implementation AppDelegate

#define USE_STAGING_FEEDS (false)

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [self getAndDeleteLegacyFavorites];
    _placeholderImages = [[NSMutableArray alloc] init];
    
    // Google Analytics
    [GAI sharedInstance].trackUncaughtExceptions = NO;
    [GAI sharedInstance].dispatchInterval = 20;
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-12099831-1"];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    UIColor *blue = [UIColor colorWithRed:0.0 green:0.2 blue:0.4 alpha:1.0];
    [[UINavigationBar appearance] setBarTintColor:blue];
    [[UINavigationBar appearance]setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont
                                                                           fontWithName:@"Times" size:20], NSFontAttributeName,
                                [UIColor whiteColor], NSForegroundColorAttributeName, nil];
    
    [[UINavigationBar appearance] setTitleTextAttributes:attributes];
    
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound
                                                                                                              categories:nil]];
    }
    
    // set badge icon to 0
    application.applicationIconBadgeNumber = 0;
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    [Bugsnag startBugsnagWithApiKey:@"7cd510d298a81f91d2ebfcfe29cba2de"];
    
    [self setupNavigation];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    NSString *dataFilePath = [docDirectory stringByAppendingPathComponent:@"livedata"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataFilePath]) {
        NSArray *dictsFromFile = [[NSMutableArray alloc] initWithContentsOfFile:dataFilePath];
        _livePosts = dictsFromFile;
        DOMParser * parser = [[DOMParser alloc] init];
        _liveEventCount = [parser upcomingPostCount:dictsFromFile];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [_blogData removeAllObjects];
    [_videoData removeAllObjects];
    [_briefingRoomData removeAllObjects];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

# pragma BackgroundFetch

-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    NSDate *fetchStart = [NSDate date];
    
    LiveViewController *liveViewController = [[LiveViewController alloc]init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    NSString *menuPath = [docDirectory stringByAppendingPathComponent:@"menuData"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:menuPath]) {
        _menuItems = [[NSMutableArray alloc] initWithContentsOfFile:menuPath];
        _liveFeed = [[_menuItems objectAtIndex:4] objectForKey:@"feed-url"];
    }else{
        _liveFeed = @"http://www.whitehouse.gov/feed/mobile/live";
    }

    [liveViewController fetchNewDataWithCompletionHandler:^(UIBackgroundFetchResult result) {
        completionHandler(result);
        
        NSDate *fetchEnd = [NSDate date];
        NSTimeInterval timeElapsed = [fetchEnd timeIntervalSinceDate:fetchStart];
        NSLog(@"Background Fetch Duration: %f seconds", timeElapsed);
    }];
}

# pragma notifications

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)localNotification{
    if (localNotification) {
        _liveLink = [localNotification.userInfo valueForKey:@"url"];
    }
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateActive) {
        NSDate *eventStart = localNotification.fireDate;
        NSDate *eventBefore = [eventStart dateByAddingTimeInterval:(-31*60)];
        NSDate* sourceDate = [NSDate date];
        NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
        NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
        NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
        NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
        NSDate *timeNow = [[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate];
        
        if([Post date:timeNow isBetweenDate:eventBefore andDate:eventStart]){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"In 30 Minutes"
                                                            message:localNotification.alertBody
                                                           delegate:self cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
}

# pragma gather and delete legacy app favorites

-(void)getAndDeleteLegacyFavorites{
    @try {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSArray *pathsList = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
        NSURL *directoryURL = [pathsList objectAtIndex:0];
        NSString *databasePath = [[directoryURL URLByAppendingPathComponent:@"feed_cache.sqlite"] absoluteString];
        
        const char* sqlStatement = "SELECT data FROM feed_items";
        sqlite3_stmt *statement;
        if (sqlite3_open([databasePath UTF8String], &(_articlesDB)) == SQLITE_OK){
            if( sqlite3_prepare_v2(_articlesDB, sqlStatement, -1, &statement, NULL) == SQLITE_OK )
            {
                FavoritesViewController * favoriteController = [[FavoritesViewController alloc] init];
                while( sqlite3_step(statement) == SQLITE_ROW )
                {
                    const void* bytes = sqlite3_column_blob(statement, 0);
                    int numBytes = sqlite3_column_bytes(statement, 0);
                    
                    // and then unarchive the feed item from the blob
                    NSData *itemData = [NSData dataWithBytes:bytes length:numBytes];
                    WHFeedItem *item = [NSKeyedUnarchiver unarchiveObjectWithData:itemData];
                    
                    NSArray *mediaSet = [item.mediaThumbnails allObjects];
                    NSString *image = [[[mediaSet objectAtIndex:0] URL] absoluteString];
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss Z"];
                    NSString *stringFromDate = [formatter stringFromDate:item.pubDate];
                    NSDictionary *postDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                              item.title, @"title",
                                              @"post", @"type",
                                              stringFromDate, @"pubDate",
                                              item.descriptionText, @"pageDescription",
                                              item.creator, @"creator",
                                              [item.link absoluteString], @"url",
                                              image , @"iPadThumbnail",
                                              image, @"mobile2048",
                                              nil];
                    Post *post = [Post postFromDictionary:postDict];
                    [favoriteController addFavoritesObject:post];
                }
                NSString *query = @"delete from feed_items";
                const char *sqlStatement = [query UTF8String];
                sqlite3_stmt *compiledStatement;
                if(sqlite3_prepare_v2(_articlesDB, sqlStatement, -1, &compiledStatement, NULL) == SQLITE_OK) {
                    // Loop through the results and add them to the feeds array
                    while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
                        NSLog(@"Deleted legacy favorite");
                    }
                    sqlite3_finalize(compiledStatement);
                }
            }
            else
            {
                NSLog( @"Failed from sqlite3_prepare_v2. Error is:  %s", sqlite3_errmsg(_articlesDB) );
            }
        }
        
        // Finalize and close database.
//        sqlite3_finalize(statement);
    }
    @catch (NSException *exception) {
        NSLog(@"Error retrieving legacy favorites");
    }
}

- (void) setupNavigation{
    // Updating menu from whitehouse JSON
    
    NSString *menuUrl = [NSString stringWithFormat:@"http://www.whitehouse.gov/sites/default/files/feeds/config.json"];
    NSURL *url = [NSURL URLWithString:menuUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    NSString *menuPath = [docDirectory stringByAppendingPathComponent:@"menuData"];
    
    NSDictionary *favMenuItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 @"Favorites", @"title",
                                 nil, @"feed-url",
                                 nil];
    
    if USE_STAGING_FEEDS {
        NSString *file = [[NSBundle mainBundle] pathForResource:@"feeds" ofType:@"json"];
        NSString *str = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:NULL];
        NSError *jsonError;
        NSData *objectData = [str dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&jsonError];
        _menuJSON = json[@"feeds"];
        [_menuJSON writeToFile:menuPath atomically: YES];
        _menuItems = [[NSMutableArray alloc] initWithArray: _menuJSON];
        [_menuItems addObject:favMenuItem];
        [self preloadData];
        
    }else{
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        operation.responseSerializer = [AFJSONResponseSerializer serializer];
        operation.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            _menuJSON = responseObject[@"feeds"];
            if (![_menuJSON writeToFile:menuPath atomically:YES]) {
                NSLog(@"Couldn't save menu config");
            }
            if ([[NSFileManager defaultManager] fileExistsAtPath:menuPath]) {
                _menuItems = [[NSMutableArray alloc] initWithContentsOfFile:menuPath];
                [_menuItems addObject:favMenuItem];
            }
            //        [_searchTableView reloadData];    uncommment to force relad of menu config
            
            [self preloadData];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:menuPath]) {
                _menuItems = [[NSMutableArray alloc] initWithContentsOfFile:menuPath];
                [_menuItems addObject:favMenuItem];
            }
            NSLog(@"Error fetching menu config");
        }];
        [operation start];
    }

    
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:menuPath]) {
        _menuItems = [[NSMutableArray alloc] initWithContentsOfFile:menuPath];
        _activeFeed = [[_menuItems objectAtIndex:0] objectForKey:@"feed-url"];
        _liveFeed = [[_menuItems objectAtIndex:4] objectForKey:@"feed-url"];
    }else{
        _activeFeed = @"http://www.whitehouse.gov/feed/mobile/blog";
        _liveFeed = @"http://www.whitehouse.gov/feed/mobile/live";
    }
    LiveViewController *liveViewController = [[LiveViewController alloc]init];
    [liveViewController fetchLiveData];
}

-(void)preloadData{
    DOMParser * parser = [[DOMParser alloc] init];
    NSURL *briefingUrl = [[NSURL alloc] initWithString:[[_menuItems objectAtIndex:1] objectForKey:@"feed-url"]];
    parser.xml = [NSString stringWithContentsOfURL:briefingUrl encoding:NSUTF8StringEncoding error:nil];
    _briefingRoomData = [[NSMutableArray alloc]init];
    [_briefingRoomData addObjectsFromArray:[parser parseFeed]];
    NSURL *photoUrl = [[NSURL alloc] initWithString:[[_menuItems objectAtIndex:2] objectForKey:@"feed-url"]];
    parser.xml = [NSString stringWithContentsOfURL:photoUrl encoding:NSUTF8StringEncoding error:nil];
    _photoData = [[NSMutableArray alloc]init];
    [_photoData addObjectsFromArray:[parser parseFeed]];
    NSURL *videoUrl = [[NSURL alloc] initWithString:[[_menuItems objectAtIndex:3] objectForKey:@"feed-url"]];
    parser.xml = [NSString stringWithContentsOfURL:videoUrl encoding:NSUTF8StringEncoding error:nil];
    _videoData = [[NSMutableArray alloc]init];
    [_videoData addObjectsFromArray:[parser parseFeed]];
}

@end
