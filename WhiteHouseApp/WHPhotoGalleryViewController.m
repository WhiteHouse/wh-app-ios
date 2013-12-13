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
//  WHPhotoGalleryViewController.m
//  WhiteHouseApp
//
//

#import "WHPhotoGalleryViewController.h"

#import <QuartzCore/QuartzCore.h>
#import "WHTrendyView.h"
#import "NINetworkImageView.h"
#import "WHPhotoViewController.h"
#import "SVPullToRefresh.h"

@implementation WHPhotoGalleryViewController

/**
 * The number of points around each thumbnail
 */
static CGFloat padding = 10;


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateThumbnails];
    [self.tableView reloadData];
}


static CGSize idealThumbSize;

+ (void)initialize
{
    idealThumbSize = CGSizeMake(150, 100);
}


- (void)calculateThumbnailSizes {
    DebugLog(@"table view bounds: %@", NSStringFromCGRect(self.tableView.bounds));
    CGFloat w = self.tableView.bounds.size.width;
    _thumbnailsPerRow = (int)floor(w / (idealThumbSize.width + padding));
    DebugLog(@"thumbnails per row: %i", _thumbnailsPerRow);
    
    CGFloat totalPadding = (_thumbnailsPerRow + 1) * padding;
    // available space / ideal space
    CGFloat ratio = (w - totalPadding) / (_thumbnailsPerRow * idealThumbSize.width);
    _thumbnailSize = CGSizeApplyAffineTransform(idealThumbSize, CGAffineTransformMakeScale(ratio, ratio));
    
    DebugLog(@"new thumbnail size: %@", NSStringFromCGSize(_thumbnailSize));
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView addPullToRefreshWithActionHandler:^{
        [self.feed fetch];
    }];
    
    self.tableView.pullToRefreshView.textColor = [UIColor lightGrayColor];
    self.tableView.pullToRefreshView.arrowColor = [UIColor lightGrayColor];
    self.tableView.pullToRefreshView.activityIndicatorViewStyle  = UIActivityIndicatorViewStyleWhite;
    self.tableView.pullToRefreshView.lastUpdatedDate = self.feed.lastUpdatedDate;
    
    [self calculateThumbnailSizes];
    
    WHTrendyView *bg = [[WHTrendyView alloc] initWithFrame:self.view.bounds];
    bg.backgroundColor = [UIColor colorWithHue:(210.0 / 365.0) saturation:0.2 brightness:0.5 alpha:1.0];
    bg.autoresizingMask = UIViewAutoresizingFlexibleDimensions;
    [self.view addSubview:bg];
    
    [self.view bringSubviewToFront:self.tableView];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsSelection = NO;
}


- (void)updateFeedItems:(NSSet *)feedItems
{
    [super updateFeedItems:feedItems];
    [self.tableView.pullToRefreshView stopAnimating];
    self.tableView.pullToRefreshView.lastUpdatedDate = self.feed.lastUpdatedDate;
}


#pragma mark Table view methods


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _thumbnailSize.height + padding;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return padding;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = [UIColor clearColor];
    return view;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // we need one row for every N pictures
    int rowCount = (self.posts.count + 1) / _thumbnailsPerRow;
    DebugLog(@"rows in gallery: %i", rowCount);
    return rowCount;
}


- (WHFeedItem *)feedItemForRow:(NSInteger)row column:(NSInteger)col
{
    int itemIndex = (row * _thumbnailsPerRow) + col;
    if (itemIndex < self.posts.count) {
        return [self.posts objectAtIndex:itemIndex];
    }
    
    return nil;
}


/**
 * Return frame for thumbnail at given column
 */
- (CGRect)frameForThumbnail:(int)col {
    return CGRectMake(((col + 1) * padding) + (col * _thumbnailSize.width), padding, _thumbnailSize.width, _thumbnailSize.height);
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static int imageTag = 1000;
    static NSString *cellID = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    for (int col = 0; col < _thumbnailsPerRow; col++) {
        WHFeedItem *item = [self feedItemForRow:indexPath.row column:col];
        WHThumbnailView *imageView = (WHThumbnailView *)[cell.contentView viewWithTag:(imageTag | col)];
        
        if (imageView == nil) {
            imageView = [[WHThumbnailView alloc] initWithFrame:[self frameForThumbnail:col]];
            [cell.contentView addSubview:imageView];
            imageView.tag = imageTag | col;
            UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
            [imageView addGestureRecognizer:tapper];
        } else {
            // set the frame to handle resizing after rotation
            imageView.frame = [self frameForThumbnail:col];
        }
        imageView.feedItem = item;
    }
    
    return cell;
}


- (void)displayFeedItem:(WHFeedItem *)feedItem
{
    [[[GAI sharedInstance] defaultTracker] sendView:[NSString stringWithFormat:@"%@/%@", [self trackingPathComponent], [feedItem trackingPathCompontent]]];

    // handle the image selection here
    WHPhotoViewController *photoView = [[WHPhotoViewController alloc] initWithNibName:nil bundle:nil];
    photoView.feedItems = self.posts;
    [self.navigationController pushViewController:photoView animated:YES];
    [photoView.photoAlbumView moveToPageAtIndex:[self.posts indexOfObject:feedItem] animated:NO];
    photoView.toolbarIsTranslucent = YES;
    photoView.hidesChromeWhenScrolling = YES;
    photoView.chromeCanBeHidden = YES;
}


- (void)tapped:(UITapGestureRecognizer *)gestureRecognizer
{
    WHThumbnailView *thumbnailView = (WHThumbnailView *)gestureRecognizer.view;
    [self displayFeedItem:thumbnailView.feedItem];
}


/**
 * Update all visible thumbnails with the correct frame, to handle UI rotation
 */
- (void)updateThumbnails {
    [self calculateThumbnailSizes];
    
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        int col = 0;
        for (UIView *thumbnail in cell.contentView.subviews) {
            DebugLog(@"col %i, thumbnail %@", col, thumbnail);
            thumbnail.frame = [self frameForThumbnail:col++];
        }
    }
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self updateThumbnails];
    [self.tableView reloadData];
}


@end
