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

NSString* const WHFeedChangedNotification = @"WHFeedChangedNotification";

@implementation WHFeed

@synthesize feedURL = _feedURL;
@synthesize items = _items;
@synthesize title;
@synthesize isDatabaseBacked;
@synthesize lastUpdatedDate;

- (id)initWithFeedURL:(NSURL *)feedURL
{
    if ((self = [super init])) {
        self.feedURL = feedURL;
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


- (void)internalFetch
{
    if (self.isDatabaseBacked && self.items == nil) {
        NSSet *databaseItems = [[WHFeedCache sharedCache] cachedItemsForURL:self.feedURL];
        if ([databaseItems count])
        {
            self.items = databaseItems;
            [self notify];
        }
    }
    
    NSData *feedData = [NSData dataWithContentsOfURL:self.feedURL];
    if (feedData) {
        NSMutableDictionary *itemsByGUID = [NSMutableDictionary dictionaryWithCapacity:self.items.count];
        for (WHFeedItem *item in self.items) {
            [itemsByGUID setObject:item forKey:item.guid];
        }
        
        WHFeedParser *parser = [[WHFeedParser alloc] initWithFeedData:feedData];
        
        // parse with block callback
        [parser parse: ^(WHFeedItem *item) {
            WHFeedItem *existingItem = [itemsByGUID objectForKey:item.guid];
            if (![existingItem isEqualToFeedItem:item]) {
                item.feedURL = self.feedURL;
                
                if (existingItem) {
                    // make sure to maintain this when items are replaced
                    item.isFavorited = existingItem.isFavorited;
                }
                
                [[WHFeedCache sharedCache] saveFeedItem:item];
                [itemsByGUID setObject:item forKey:item.guid];
            }
        }];
        
        self.items = [NSSet setWithArray:[itemsByGUID allValues]];
        [self notify];
    }
}


- (void)fetch
{
    self.lastUpdatedDate = [NSDate date];
    dispatch_async(_queue, ^{
        NINetworkActivityTaskDidStart();
        [self internalFetch];
        NINetworkActivityTaskDidFinish();
    });
}


- (NSSet *)favorites
{
    return [[WHFeedCache sharedCache] favoritedItemsForURL:self.feedURL];
}


@end
