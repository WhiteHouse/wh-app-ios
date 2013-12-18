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
//  WHFavoritesViewController.m
//  WhiteHouseApp
//
//

#import "WHFavoritesViewController.h"

#import "UIViewController+WHFeedItemPresentation.h"
#import "WHPhotoViewController.h"
#import "WHFeedCollection.h"
#import "WHTrendyView.h"
#import "WHFeedCache.h"

@interface WHFavoritesViewController ()
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSDictionary *favoritesDict;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *zeroStateView;
@end

@implementation WHFavoritesViewController

@synthesize sections = _sections;
@synthesize favoritesDict = _favoritesDict;
@synthesize tableView = _tableView;
@synthesize zeroStateView = _zeroStateView;


- (void)reloadFavorites
{
    NSArray *feeds = [[WHFeedCollection sharedFeedCollection] allFeeds];
    NSMutableArray *feedsWithFavorites = [NSMutableArray array];
    NSMutableDictionary *favoritesDict = [NSMutableDictionary dictionary];
    for (WHFeed *feed in feeds) {
        NSSet *favorites = [feed favorites];
        DebugLog(@"Feed %@ has %i favorites", feed.feedURL, favorites.count);
        if ([favorites count]) {
            [feedsWithFavorites addObject:feed];
            favoritesDict[feed.feedURL] = favorites;
        }
    }
    
    self.sections = feedsWithFavorites;
    self.favoritesDict = favoritesDict;
    
    if (self.sections.count) {
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                    target:self
                                                                                    action:@selector(toggleEditing)];
        self.navigationItem.rightBarButtonItem = editButton;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}


- (void)viewDidLoad
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleDimensions;
    [self.view addSubview:tableView];
    
    self.tableView = tableView;
    
    WHTrendyView *zeroState = [[WHTrendyView alloc] initWithFrame:self.view.bounds];
    zeroState.backgroundColor = [UIColor whiteColor];
    zeroState.autoresizingMask = UIViewAutoresizingFlexibleDimensions;
    [self.view addSubview:zeroState];
    self.zeroStateView = zeroState;
    
    UIImageView *messageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"favorites-zero-state"]];
    messageView.center = zeroState.center;
    messageView.frame = CGRectOffset(messageView.frame, 0, 0.5);
    messageView.autoresizingMask = UIViewAutoresizingFlexibleMargins;
    [zeroState addSubview:messageView];
    
    DebugLog(@"view bounds = %@", NSStringFromCGRect(self.view.bounds));
}


- (BOOL)shouldShowZeroState
{
    return self.sections.count == 0;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reloadFavorites];
    
    if ([self shouldShowZeroState]) {
        self.zeroStateView.hidden = NO;
        self.tableView.hidden = YES;
    } else {
        self.zeroStateView.hidden = YES;
        self.tableView.hidden = NO;
    }
    
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return ((WHFeed *)(self.sections)[section]).title;
}


- (NSArray *)favesForSection:(NSInteger)section
{
    WHFeed *feed = (self.sections)[section];
    NSArray *itemArray = [(self.favoritesDict)[feed.feedURL] allObjects];
    return [itemArray sortedArrayUsingComparator:^NSComparisonResult(WHFeedItem *a, WHFeedItem *b) {
        return [b.pubDate compare:a.pubDate];
    }];
}


- (WHFeedItem *)favoriteForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self favesForSection:indexPath.section][indexPath.row];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self favesForSection:section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        cell.textLabel.font = [WHStyle headingFontWithSize:16];
        cell.textLabel.textColor = [WHStyle primaryColor];
        cell.textLabel.numberOfLines = 2;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    WHFeedItem *item = [self favoriteForRowAtIndexPath:indexPath];
    cell.textLabel.text = item.title;
    
    return cell;
}

#define TITLE_FONT_SIZE 16
#define HEADER_PADDING 4
#define HEADER_HEIGHT (TITLE_FONT_SIZE + HEADER_PADDING + HEADER_PADDING)

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return HEADER_HEIGHT;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, HEADER_HEIGHT)];
    headerView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"section-bar"]];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(HEADER_PADDING, HEADER_PADDING, 320, TITLE_FONT_SIZE)];
    label.backgroundColor = [UIColor clearColor];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.font = [WHStyle detailFontWithSize:14];
    label.textColor = [UIColor blackColor];
    label.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    label.shadowOffset = CGSizeMake(0, 1);
    [headerView addSubview:label];
    return headerView;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WHFeedItem *item = [self favoriteForRowAtIndexPath:indexPath];
    if (item.mediaContents.count) {
        // handle the image selection here
        WHPhotoViewController *photoView = [[WHPhotoViewController alloc] initWithNibName:nil bundle:nil];
        photoView.feedItems = [self favesForSection:indexPath.section];
        [self.navigationController pushViewController:photoView animated:YES];
        [photoView.photoAlbumView moveToPageAtIndex:[photoView.feedItems indexOfObject:item] animated:NO];
        photoView.toolbarIsTranslucent = YES;
        photoView.hidesChromeWhenScrolling = YES;
        photoView.chromeCanBeHidden = YES;
    } else {
        [self displayFeedItem:item];
    }
}


#pragma mark - editing


- (void)toggleEditing
{
    [self.tableView setEditing:!self.tableView.isEditing animated:YES];
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        WHFeedItem *item = [self favoriteForRowAtIndexPath:indexPath];
        item.isFavorited = NO;
        [[WHFeedCache sharedCache] saveFeedItem:item];
        [self reloadFavorites];
        [self.tableView reloadData];
    }
}


@end
