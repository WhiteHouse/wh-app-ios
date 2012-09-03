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
//  WHLivePopoverViewController.m
//  WhiteHouseApp
//
//

#import "WHLivePopoverViewController.h"

#import <MediaPlayer/MediaPlayer.h>
#import "WHFeedItem.h"


@implementation WHLivePopoverViewController

@synthesize items;
@synthesize parentFeedViewController;
@synthesize popoverController;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


#pragma mark - Table view data source

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
        cell.textLabel.textColor = [WHStyle primaryColor];
        cell.textLabel.numberOfLines = 2;
        cell.detailTextLabel.font = [WHStyle detailFontWithSize:12];
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        cell.detailTextLabel.text = @"Tap to watch now";
    }
    
    WHFeedItem *item = [self.items objectAtIndex:indexPath.row];
    cell.textLabel.text = item.title;
    
    return cell;
}


- (void)deselect:(NSIndexPath *)path
{
    [self.tableView deselectRowAtIndexPath:path animated:YES];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSelector:@selector(deselect:) withObject:indexPath afterDelay:0.01];
    WHFeedItem *item = [self.items objectAtIndex:indexPath.row];
    
    if (item.enclosureURL) {
        DebugLog(@"Playing video at %@", item.enclosureURL);    
        MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:item.enclosureURL];
        [self.parentFeedViewController presentMoviePlayerViewControllerAnimated:player];
        [self.popoverController dismissPopoverAnimated:NO];
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
    NSInteger reason = [[notification.userInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if (reason == MPMovieFinishReasonPlaybackError) {
        NSError *error = [notification.userInfo objectForKey:@"error"];
        
        NSString *msg = NSLocalizedString(@"VideoErrorMessage", @"There was a problem playing this video. Please try again later.");
        NSString *errorMessage = [NSString stringWithFormat:@"%@\n\n(%@)", msg, [error localizedDescription]];
        NSString *title = NSLocalizedString(@"VideoErrorTitle", @"Playblack Error");
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alert show];
    }
    
    [self performSelector:@selector(unregister) withObject:nil afterDelay:0.1];
}


@end
