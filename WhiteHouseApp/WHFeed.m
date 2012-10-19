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
//  WHFeedController.m
//  WhiteHouseApp
//
//

#import "WHFeed.h"

#import "WHFeedCache.h"
#import "WHRemoteFile.h"

NSString* const WHFeedChangedNotification = @"WHFeedChangedNotification";


@interface WHFeed ()
@property (nonatomic, strong) WHRemoteFile *cache;
@end

@implementation WHFeed

@synthesize feedURL = _feedURL;
@synthesize items = _items;
@synthesize title;
@synthesize isDatabaseBacked;
@synthesize lastUpdatedDate;
@synthesize cache = _cache;

- (id)initWithFeedURL:(NSURL *)feedURL
{
    if ((self = [super init])) {
        self.feedURL = feedURL;
        self.cache = [[WHRemoteFile alloc] initWithBundleResource:nil ofType:nil remoteURL:self.feedURL];
        _queue = dispatch_queue_create("gov.eop.wh.feed_loading", NULL);
    }
    
    return self;
}


- (void)notify
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:WHFeedChangedNotification object:self userInfo:nil];
    });
}


- (NSSet *)parseFeedData:(NSData *)data
{
    NSMutableSet *items = [NSMutableSet set];
    WHFeedParser *parser = [[WHFeedParser alloc] initWithFeedData:data];
    [parser parse: ^(WHFeedItem *item) {
        item.feedURL = self.feedURL;
        [items addObject:item];
    }];
    return items;
}


- (void)internalFetch
{
    if (self.items == nil && self.isDatabaseBacked) {
        DebugLog(@"%@ Loading local cache", self.feedURL);
        self.items = [self parseFeedData:[self.cache data]];
        if (self.items.count) {
            DebugLog(@"%@ Had %i cached items", self.feedURL, self.items.count);
            [self notify];
        }
    }
    
    DebugLog(@"Updating from URL");
    [self.cache updateWithValidator:^BOOL(NSData *remoteData) {
        DebugLog(@"%@ Got feed data (%i bytes)", self.feedURL, remoteData.length);
        self.items = [self parseFeedData:remoteData];
        self.lastUpdatedDate = [NSDate date];
        [self notify];
        return self.isDatabaseBacked;
    }];
}


- (void)fetch
{
    dispatch_async(_queue, ^{
        [self internalFetch];
    });
}


- (NSSet *)favorites
{
    return [[WHFeedCache sharedCache] favoritedItemsForURL:self.feedURL];
}


@end
