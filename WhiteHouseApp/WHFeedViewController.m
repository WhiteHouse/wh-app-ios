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
//  WHFeedViewController.m
//  WhiteHouseApp
//
//

#import "WHFeedViewController.h"

#import "WHLivePopoverViewController.h"
#import "WHLiveBarController.h"
#import "WHFeedCollection.h"
#import "WHLiveController.h"
#import "WHAppDelegate.h"
#import "CustomBadge.h"

NSDate *DayFromDate(NSDate *date)
{
    NSCalendar *cal = [NSCalendar autoupdatingCurrentCalendar];
    NSDate *day;
    [cal rangeOfUnit:NSDayCalendarUnit startDate:&day interval:NULL forDate:date];
    return day;
}



@interface WHFeedViewController ()
@property (nonatomic, strong) UIBarButtonItem *liveBarButtonItem;
@end


@implementation WHFeedViewController

@synthesize tableView = _tableView;
@synthesize posts = _posts;
@synthesize feed = _feed;

@synthesize liveBar;
@synthesize isLiveBarHidden;
@synthesize popover;

@synthesize liveBarButtonItem;


- (id)initWithFeed:(WHFeed *)feed
{
    if ((self = [self initWithNibName:nil bundle:nil]))
    {
        self.feed = feed;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleDimensions;
    [self.view addSubview:tableView];
    
    self.tableView = tableView;
    
    // listen for feed changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedChanged:) name:WHFeedChangedNotification object:self.feed];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(liveBarWillAppear:) name:WHLiveBarWillAppearNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(liveBarWillHide:) name:WHLiveBarWillHideNotification object:nil];
}


- (void)liveBarWillAppear:(NSNotification *)notification
{
    [self setLiveBarVisible:YES animated:YES];
}


- (void)liveBarWillHide:(NSNotification *)notification
{
    [self setLiveBarVisible:NO animated:YES];
}


- (void)showLivePopover:(id)sender
{
    if (popover) {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    } else {
        WHLiveBarController *liveBarController = ((WHAppDelegate *)[UIApplication sharedApplication].delegate).liveBarController;
        WHLivePopoverViewController *live = [[WHLivePopoverViewController alloc] initWithNibName:nil bundle:nil];
        live.items = liveBarController.items;
        live.parentFeedViewController = self;
        
        self.popover = [[UIPopoverController alloc] initWithContentViewController:live];
        popover.popoverContentSize = CGSizeMake(320, 480);
        popover.delegate = self;
        
        live.popoverController = popover;
        
        [popover presentPopoverFromBarButtonItem:self.liveBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}


- (void)addLiveButton
{
    if (self.liveBarButtonItem == nil) {
        UIImage *buttonBackground = [UIImage imageNamed:@"BarButtonBackground"];
        
        // use cap insets that leave a 1x1 pixel area in the center of the image
        UIEdgeInsets capInsets = UIEdgeInsetsMake(15, 5, 14, 5);
        UIImage *stretchy = [buttonBackground resizableImageWithCapInsets:capInsets];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        // this image should stretch to fill the button
        [button setBackgroundImage:stretchy forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [button setTitle:@"   Watch Now   " forState:UIControlStateNormal];
        [button sizeToFit];
        
        // add our handy-dandy badge
        WHLiveBarController *liveBarController = ((WHAppDelegate *)[UIApplication sharedApplication].delegate).liveBarController;
        NSInteger n = liveBarController.items.count;
        
        NSString *badgeString = [NSString stringWithFormat:@"%i", n];
        CustomBadge *badge = [CustomBadge customBadgeWithString:badgeString];
        badge.frame = CGRectOffset(badge.frame, button.bounds.size.width - 8, -6);
        badge.badgeInsetColor = [UIColor orangeColor];
        badge.badgeShining = NO;
        [button addSubview:badge];
        
        UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, button.bounds.size.width + 16, button.bounds.size.height)];
        [buttonContainer addSubview:button];
        
        // set up the popover callback
        [button addTarget:self action:@selector(showLivePopover:) forControlEvents:UIControlEventTouchUpInside];
        
        self.liveBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:buttonContainer];
    }
    
    self.navigationItem.rightBarButtonItem = self.liveBarButtonItem;
}


- (void)setLiveBarVisible:(BOOL)visible animated:(BOOL)animated
{
    if (self.isLiveBarHidden) {
        return;
    }
    
    if (NIIsPad()) {
        // clear the button item to force it to be recreated (with the correct badge count, etc.)
        self.liveBarButtonItem = nil;
        
        if (visible) {
            [self addLiveButton];
            
        } else {
            self.navigationItem.rightBarButtonItem = nil;
        }
        return;
    }
    
    CGRect destTableViewFrame = self.view.bounds;
    
    if (visible) {
        // shrink the table view down by 20px
        destTableViewFrame.size.height -= 20;
        destTableViewFrame.origin.y = 20;
    }
    
    if (animated) {
        // begin an animation block
        [UIView beginAnimations:@"showLiveBar" context:nil];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDelay:(visible ? 0.2 : 0)];
        [UIView setAnimationDuration:(visible ? 0.2 : 0.1)];
    }
    
    self.tableView.frame = destTableViewFrame;
    
    if (animated) {
        [UIView commitAnimations];
    }
}


- (NSArray *)sortFeedItems:(NSArray *)unsortedItems
{
    // sort by reverse chronological order
    return [unsortedItems sortedArrayUsingComparator:^NSComparisonResult(WHFeedItem *a, WHFeedItem *b) {
        return [b.pubDate compare:a.pubDate];
    }];
}


- (void)updateFeedItems:(NSSet *)feedItems
{
    self.posts = [self sortFeedItems:feedItems.allObjects];
    [self.tableView reloadData];
}


- (void)feedChanged:(NSNotification *)notification
{
    ASSERT_MAIN_THREAD;
    [self updateFeedItems:((WHFeed *)notification.object).items];
}


- (void)viewWillAppear:(BOOL)animated
{
    [[GANTracker sharedTracker] trackPageview:[self trackingPathComponent] withError:nil];
    
    // get the root/shared live bar controller
    WHLiveBarController *liveBarController = ((WHAppDelegate *)[UIApplication sharedApplication].delegate).liveBarController;
    [liveBarController.liveBarView removeFromSuperview];
    
    if (!self.isLiveBarHidden) {
        if (NIIsPad()) {
            if (liveBarController.items.count) {
                [self addLiveButton];
            }
        } else {
            liveBarController.parentViewController = self;
            self.liveBar = liveBarController.liveBarView;
            [self.view addSubview:self.liveBar];
            
            if (liveBarController.items.count) {
                [self setLiveBarVisible:YES animated:NO];
            }
        }
    }
    
    if (!self.feed.items.count) {
        [self.feed fetch];
    }
}


- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WHLiveEventsChangedNotification object:nil];
    if (NIIsPad()) {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.posts = [NSMutableArray array];
    self.tableView = nil;
    self.liveBar = nil;
    
    // stop listening for feed changes until we reload the view
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WHFeedChangedNotification object:self.feed];
}


#pragma mark - stub table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}


@end
