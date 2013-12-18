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
//  WHLiveTableViewDataSource.m
//  WhiteHouseApp
//
//

#import "WHLiveBarController.h"

#import "WHLiveController.h"
#import "WHFeedItem.h"

#import <MediaPlayer/MediaPlayer.h>

NSString * const WHLiveBarWillAppearNotification = @"WHLiveBarDidAppearNotification";
NSString * const WHLiveBarWillHideNotification = @"WHLiveBarDidHideNotification";

@interface WHLiveBarController ()
@property (nonatomic, strong) UITableView *liveBarTableView;
@property (nonatomic, strong) UILabel *liveBarTitleLabel;
@end

@implementation WHLiveBarController

@synthesize items = _items;
@synthesize parentViewController = _parentViewController;

@synthesize liveBarView = _liveBarView;
@synthesize liveBarTableView;
@synthesize liveBarTitleLabel;


- (id)init
{
    if ((self = [super init])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(liveFeedChanged:) name:WHLiveEventsChangedNotification object:nil];
    }
    return self;
}

- (WHPullDownView *)liveBarView
{
    if (_liveBarView == nil) {
        [self loadLiveBar];
    }
    return _liveBarView;
}


- (void)setTitleLabel
{
    if (self.items.count == 1) {
        self.liveBarTitleLabel.text = [(self.items)[0] title];
    } else if (self.items.count > 1) {
        self.liveBarTitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"LiveBarTitleFormat", @"%i events live now"), self.items.count];
    }
}


- (void)liveFeedChanged:(NSNotification *)notification
{
    DebugLog(@"got live items");
    self.items = (notification.userInfo)[WHLiveEventsChangedLiveItemsKey];
    if (self.items.count) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WHLiveBarWillAppearNotification object:self];
        [self show];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:WHLiveBarWillHideNotification object:self];
        [self hide];
    }
    [self setTitleLabel];
    [self.liveBarTableView reloadData];
    
    /*
     Resize the table view to match its contents. This might be tricky if the table view
     changes while the live bar is pulled down.
     */
    CGRect tableFrame = self.liveBarTableView.frame;
    tableFrame.size.height = self.liveBarTableView.contentSize.height;
    tableFrame.origin.y = self.liveBarView.handleView.frame.origin.y - tableFrame.size.height;
    self.liveBarTableView.frame = tableFrame;
}


- (void)hide
{
    [UIView beginAnimations:@"hideLiveBar" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    CGRect hiddenFrame = self.liveBarView.handleView.bounds;
    hiddenFrame.size.height = 0;
    self.liveBarView.frame = hiddenFrame;
    
    [UIView commitAnimations];
}


- (void)show
{
    [UIView beginAnimations:@"showLiveBar" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    self.liveBarView.frame = self.liveBarView.handleView.bounds;
    
    [UIView commitAnimations];
}


- (void)loadLiveBar
{
    UIImageView *bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"live-bar-content"]];
    UITableView *liveTable = [[UITableView alloc] initWithFrame:bgImageView.bounds style:UITableViewStylePlain];
    self.liveBarTableView = liveTable;
    liveTable.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    liveTable.backgroundView = bgImageView;
    liveTable.separatorColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    liveTable.dataSource = self;
    liveTable.delegate = self;
    
    UIImageView *handleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"live-bar-handle"]];
    handleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    handleView.contentMode = UIViewContentModeScaleToFill;
    
    UILabel *liveBarTitle = [[UILabel alloc] initWithFrame:CGRectMake(5, 6, handleView.bounds.size.width - 10, 12)];
    liveBarTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    liveBarTitle.backgroundColor = [UIColor clearColor];
    liveBarTitle.shadowColor = [UIColor colorWithWhite:0 alpha:0.25];
    liveBarTitle.shadowOffset = CGSizeMake(0, -1);
    liveBarTitle.font = [UIFont fontWithName:AppConfig(@"LiveBarTitleFontName") size:12];
    liveBarTitle.textColor = [UIColor whiteColor];
    
    liveBarTitle.text = @"TITLE GOES HERE";
    liveBarTitle.textAlignment = UITextAlignmentCenter;
    liveBarTitle.numberOfLines = 0;
    self.liveBarTitleLabel = liveBarTitle;
    
    int handleLabelFontSize = 9;
    UILabel *handleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, handleView.bounds.size.height - handleLabelFontSize - 10, handleView.bounds.size.width, handleLabelFontSize)];
    handleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    handleLabel.textAlignment = UITextAlignmentCenter;
    handleLabel.text = NSLocalizedString(@"LiveBarHandleLabel", @"WATCH LIVE");
    handleLabel.font = [UIFont fontWithName:AppConfig(@"LiveBarHandleFontName") size:handleLabelFontSize];
    handleLabel.textColor = [UIColor colorWithWhite:0 alpha:0.4];
    handleLabel.backgroundColor = [UIColor clearColor];
    [handleView addSubview:handleLabel];
    
    UIView *barHighlight = [[UIView alloc] initWithFrame:CGRectMake(0, 0, handleView.bounds.size.width, 1)];
    barHighlight.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    barHighlight.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [handleView addSubview:barHighlight];
    
    [handleView addSubview:liveBarTitle];
    
    [self setTitleLabel];
    
    self.liveBarView = [[WHPullDownView alloc] initWithContentView:liveTable handleView:handleView];
    self.liveBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.liveBarView.frame = CGRectOffset(self.liveBarView.frame, 0, -self.liveBarView.frame.size.height);
}

#pragma mark - table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ident = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ident];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [WHStyle headingFontWithSize:18];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.numberOfLines = 2;
        cell.detailTextLabel.font = [WHStyle detailFontWithSize:12];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.7];
        cell.detailTextLabel.text = NSLocalizedString(@"LiveBarPrompting", @"Tap to watch now");
    }

    WHFeedItem *item = (self.items)[indexPath.row];
    cell.textLabel.text = item.title;
    
    return cell;
}

- (void)deselect:(NSIndexPath *)path
{
    [self.liveBarTableView deselectRowAtIndexPath:path animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSelector:@selector(deselect:) withObject:indexPath afterDelay:0.01];
    WHFeedItem *item = (self.items)[indexPath.row];
    
    if (item.enclosureURL) {
        DebugLog(@"Playing video at %@", item.enclosureURL);    
        MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:item.enclosureURL];
        [self.parentViewController presentMoviePlayerViewControllerAnimated:player];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:player.moviePlayer];
    }
}

#pragma mark - movie player methods

- (void)unregister
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)movieFinished:(NSNotification *)notification
{
    DebugLog(@"movie finished: %@", notification.userInfo);
    NSInteger reason = [(notification.userInfo)[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if (reason == MPMovieFinishReasonPlaybackError) {
        NSError *error = (notification.userInfo)[@"error"];
        
        NSString *msg = NSLocalizedString(@"VideoErrorMessage", @"There was a problem playing this video. Please try again later.");
        NSString *errorMessage = [NSString stringWithFormat:@"%@\n\n(%@)", msg, [error localizedDescription]];
        NSString *title = NSLocalizedString(@"VideoErrorTitle", @"Playblack Error");
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alert show];
    }
    
    [self performSelector:@selector(unregister) withObject:nil afterDelay:0.1];
}

@end
