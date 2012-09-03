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
//  WHFeedController.h
//  WhiteHouseApp
//
//

#import <Foundation/Foundation.h>
#import "WHFeedParser.h"

/**
 * The notification name used whenever the feed finds items (cached or remote).
 */
extern NSString* const WHFeedChangedNotification;

/**
 * A simple class to manage an RSS feed and post notifications of found items.
 */
@interface WHFeed : NSObject {
    dispatch_queue_t _queue;
}

/**
 * The URL to load items from.
 */
@property (nonatomic, strong) NSURL *feedURL;

/**
 * The title of the feed
 */
@property (nonatomic, strong) NSString *title;

/**
 * The fetched collection of items.
 */
@property (atomic, strong) NSSet *items;

/**
 * When this property is true, then the feed is backed by the database
 */
@property (nonatomic, assign) BOOL isDatabaseBacked;


/**
 * The last time the feed was successfully updated
 */
@property (nonatomic, strong) NSDate *lastUpdatedDate;

/**
 * The designated initializer.
 *
 * Returns a new feed controller for the given feed URL.
 */
- (id)initWithFeedURL:(NSURL *)feedURL;

/**
 * Begin loading feed items.
 * 
 * This will immediately look for items in the cache, and and then start an async
 * task to load items from the feed URL.
 */
- (void)fetch;

/**
 * Returns a list of items from the feed which are marked as favorites
 */
- (NSSet *)favorites;

@end
