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
//  WHLiveController.m
//  WhiteHouseApp
//
//

#import "WHLiveController.h"


NSString * const WHLiveEventsChangedNotification = @"WHLiveEventsChangedNotification";
NSString * const WHLiveEventsChangedLiveItemsKey = @"liveItems";

@implementation WHLiveController

@synthesize feed = _feed;

- (id)initWithFeed:(WHFeed *)feed
{
    if ((self = [super init])) {
        self.feed = feed;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(liveFeedChanged:) name:WHFeedChangedNotification object:feed];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
}

- (void)liveFeedChanged:(NSNotification *)notification
{
    DebugLog(@"got live items... considering them now");
    
    NSDate *now = [NSDate date];
    NSArray *itemArray = [[(WHFeed *)notification.object items] allObjects];
    NSArray *liveItems = [itemArray filteredArrayUsingBlock:^(WHFeedItem *item) {
        return (BOOL)([now compare:item.pubDate] == NSOrderedDescending);
    }];
    
    DebugLog(@"%i items are actually live", liveItems.count);

    // show the live bar
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:liveItems forKey:WHLiveEventsChangedLiveItemsKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:WHLiveEventsChangedNotification object:self userInfo:userInfo];
}

- (void)startUpdating
{
    DebugLog(@"fetching live items...");
    [self performSelector:@selector(startUpdating) withObject:nil afterDelay:30];
    [self.feed fetch];
}

- (void)stopUpdating
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

@end
