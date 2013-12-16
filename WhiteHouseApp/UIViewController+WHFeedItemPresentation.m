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
//  UIViewController+WHFeedItemPresentation.m
//  WhiteHouseApp
//
//

#import "UIViewController+WHFeedItemPresentation.h"

#import <MediaPlayer/MediaPlayer.h>
#import "WHYouTubePlayerViewController.h"
#import "WHArticleViewController.h"
#import "WHFeedItem.h"

@implementation UIViewController (WHFeedItemPresentation)


- (NSString *)trackingPathComponent
{
    return [@"/" stringByAppendingString:self.title];
}


- (void)displayFeedItem:(WHFeedItem *)item
{
    [[[GAI sharedInstance] defaultTracker] sendView:[NSString stringWithFormat:@"%@/%@", [self trackingPathComponent], [item trackingPathCompontent]]];
    
    if (item.enclosureURL) {
        NSString *host = item.enclosureURL.host;
        if ([host rangeOfString:@"youtube"].location != NSNotFound || [host rangeOfString:@"youtu.be"].location != NSNotFound) {
            WHYouTubePlayerViewController *videoPlayer = [[WHYouTubePlayerViewController alloc] initWithVideoURL:item.enclosureURL];
            [self.navigationController pushViewController:videoPlayer animated:YES];
        } else {
            MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:item.enclosureURL];
            [self presentMoviePlayerViewControllerAnimated:player];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:player.moviePlayer];
        }
    } else {
        WHArticleViewController *web = [[WHArticleViewController alloc] initWithNibName:nil bundle:nil];
        web.feedItem = item;
        [self.navigationController pushViewController:web animated:YES];
    }
}


#pragma mark - movie player methods


- (void)unregister
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}


- (void)movieFinished:(NSNotification *)notification
{
    DebugLog(@"movie finished: %@", notification.userInfo);
    NSInteger reason = [[notification.userInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if (reason == MPMovieFinishReasonPlaybackError) {
        NSError *error = [notification.userInfo objectForKey:@"error"];
        
        NSString *errorTitle = NSLocalizedString(@"VideoErrorTitle", @"Title for video playback error alert");
        NSString *localizedErrorMessage = NSLocalizedString(@"VideoErrorMessage", @"Error shown when video fails to play");
        NSString *errorMessage = [NSString stringWithFormat:@"%@\n\n (%@)", localizedErrorMessage, [error localizedDescription]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorTitle
                                                        message:errorMessage
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    [self performSelector:@selector(unregister) withObject:nil afterDelay:0.1];
}


@end
