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
//  WHLiveFeedViewController.m
//  WhiteHouseApp
//
//

#import "WHLiveFeedViewController.h"

#import "WHTrendyView.h"

@interface WHLiveFeedViewController ()
/**
 * Displays a placeholder to inform the user when no live events are scheduled
 */
@property (nonatomic, strong) UIView *emptyFeedInfoView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign) BOOL feedIsLoaded;
@end

@implementation WHLiveFeedViewController

@synthesize emptyFeedInfoView;
@synthesize activityIndicator;
@synthesize feedIsLoaded;


- (id)initWithFeed:(WHFeed *)feed
{
    if ((self = [super initWithFeed:feed])) {
        self.isLiveBarHidden = YES;
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    WHTrendyView *gradient = [[WHTrendyView alloc] initWithFrame:self.view.bounds];
    gradient.startColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    gradient.endColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    gradient.autoresizingMask = UIViewAutoresizingFlexibleDimensions;
    [self.view addSubview:gradient];
    [self.view bringSubviewToFront:self.tableView];
    
    self.emptyFeedInfoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"live-feed-zero-state"]];
    self.emptyFeedInfoView.center = gradient.center;
    self.emptyFeedInfoView.autoresizingMask = UIViewAutoresizingFlexibleMargins;
    [self.view addSubview:self.emptyFeedInfoView];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator.center = self.tableView.center;
    self.activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleMargins;
    [self.view addSubview:self.activityIndicator];
    
    self.feedIsLoaded = self.feed.items.count > 0;
}


- (void)configureViews
{
    if (!self.feedIsLoaded) {
        // still waiting on feeds...
        self.tableView.hidden = YES;
        self.emptyFeedInfoView.hidden = YES;
        [self.activityIndicator startAnimating];
    } else if ([self.posts count]) {
        // show the table view, hide the placeholder view
        self.tableView.hidden = NO;
        self.emptyFeedInfoView.hidden = YES;
        [self.activityIndicator stopAnimating];
    } else {
        // vice versa
        self.tableView.hidden = YES;
        self.emptyFeedInfoView.hidden = NO;
        [self.activityIndicator stopAnimating];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self configureViews];
}


- (NSArray *)sortFeedItems:(NSArray *)unsortedItems
{
    return [unsortedItems reverseObjectEnumerator].allObjects;
}

- (void)updateFeedItems:(NSSet *)feedItems
{
    self.feedIsLoaded = YES;
    [self configureViews];
    [super updateFeedItems:feedItems];
}


- (void)configureCell:(UITableViewCell *)cell forFeedItem:(WHFeedItem *)item
{
    [super configureCell:cell forFeedItem:item];
    
    // if the published date is in the future...
    if ([[NSDate date] laterDate:item.pubDate] == item.pubDate) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WHFeedItem *item = [self feedItemForRowAtIndexPath:indexPath];
    if ([[NSDate date] laterDate:item.pubDate] == item.pubDate) {
        return;
    } else {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}


@end
