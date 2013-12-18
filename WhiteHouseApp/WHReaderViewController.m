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
//  WHReaderViewController.m
//  WhiteHouseApp
//
//

#import "WHReaderViewController.h"

#import "WHSharingUtilities.h"
#import "WHReaderPanelView.h"
#import "SVPullToRefresh.h"

@interface WHReaderViewController ()
@property (nonatomic, strong) WHSharingUtilities *sharing;
@end

#define READER_PANELS_PER_ROW 2


@implementation WHReaderViewController

@synthesize showAuthor;
@synthesize pressToShare;
@synthesize sharing;


- (id)initWithFeed:(WHFeed *)feed
{
    if ((self = [super initWithFeed:feed])) {
        self.sharing = [[WHSharingUtilities alloc] initWithViewController:self];
    }
    
    return self;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self sizePanels];
}


- (void)viewDidAppear:(BOOL)animated
{
    if (self.pressToShare) {
        [WHSharingUtilities showVideoInstructions];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    
    WHReaderViewController * __weak weakSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        [weakSelf.feed fetch];
    }];
}


- (void)updateFeedItems:(NSSet *)feedItems
{
    [self.tableView.pullToRefreshView stopAnimating];
    self.tableView.pullToRefreshView.lastUpdatedDate = self.feed.lastUpdatedDate;
    [super updateFeedItems:feedItems];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (self.posts.count + 1) / READER_PANELS_PER_ROW; // (NSInteger)floor(self.posts.count / 2.0);
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self panelSize].height + padding;
}

#define READER_CELL_IDENT @"Cell"
#define READER_TAG_MASK (1 << 10)


static CGFloat padding = 10.0;


- (CGSize)panelSize
{
    CGFloat tableWidth = self.tableView.bounds.size.width;
    CGFloat n = READER_PANELS_PER_ROW;
    CGFloat panelWidth = (tableWidth - ((n + 1) * padding)) / n;
    return CGSizeMake(panelWidth, panelWidth);
}


- (CGRect)frameForPanel:(int)index {
    CGSize panelSize = [self panelSize];
    CGFloat totalPadding = (index + 1) * padding;
    CGFloat offsetX = totalPadding + (index * panelSize.width);
    return CGRectMake(offsetX, padding, panelSize.width, panelSize.height);
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:READER_CELL_IDENT];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:READER_CELL_IDENT];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        for (int ii = 0; ii < READER_PANELS_PER_ROW; ii++) {
            WHReaderPanelView *panel = [[WHReaderPanelView alloc] initWithFrame:[self frameForPanel:ii]];
            panel.showAuthor = self.showAuthor;
            panel.tag = ii | READER_TAG_MASK;
            [cell.contentView addSubview:panel];
        }
    }
    
    for (int ii = 0; ii < READER_PANELS_PER_ROW; ii++) {
        WHReaderPanelView *panel = (WHReaderPanelView *)[cell.contentView viewWithTag:ii | READER_TAG_MASK];
        panel.frame = [self frameForPanel:ii];
        int itemIndex = (indexPath.row * READER_PANELS_PER_ROW) + ii;
        if (itemIndex < self.posts.count) {
            [panel setHidden:NO];
            WHFeedItem *item = (self.posts)[itemIndex];
            panel.feedItem = item;
            
            UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(itemTapped:)];
            [panel addGestureRecognizer:tapper];
            
            if (self.pressToShare) {
                UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(itemPressed:)];
                [panel addGestureRecognizer:longPress];
            }
        } else {
            [panel setHidden:YES];
        }
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // do nothing
}


- (void)sizePanels
{
    for (UITableViewCell *cell in [self.tableView visibleCells]) {
        int ii = 0;
        for (UIView *panel in cell.contentView.subviews) {
            panel.frame = [self frameForPanel:ii];
            ii++;
        }
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    DebugLog(@"Should autorotate?");
    return NIIsSupportedOrientation(toInterfaceOrientation);
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self sizePanels];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadData];
}


#pragma mark - item selection

- (void)itemTapped:(UITapGestureRecognizer *)gestureRecognizer
{
    WHReaderPanelView *panel = (WHReaderPanelView *)gestureRecognizer.view;
    WHFeedItem *item = panel.feedItem;
    [self displayFeedItem:item];
}


- (void)itemPressed:(UILongPressGestureRecognizer *)gestureRecognizer
{
    WHReaderPanelView *panel = (WHReaderPanelView *)gestureRecognizer.view;
    WHFeedItem *item = panel.feedItem;
    [self.sharing share:item];
}


@end
