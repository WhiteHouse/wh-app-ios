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
//  WHFeedItem.h
//  WhiteHouseApp
//
//

#import <Foundation/Foundation.h>

/**
 * Represents the RSS <media:thumbnail>, <media:content> and <media:enclosure> elements
 */
@interface WHMediaElement : NSObject <NSCoding>
//@property (nonatomic, assign) CGSize size;
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSString *medium;
@property (nonatomic, strong) NSString *type;
@end

/**
 * Represents an RSS <item>
 */
@interface WHFeedItem : NSObject <NSCoding>

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *guid;
@property (nonatomic, strong) NSURL *link;
@property (nonatomic, strong) NSString *descriptionText;
@property (nonatomic, strong) NSString *descriptionHTML;
@property (nonatomic, strong) NSArray *categories;
@property (nonatomic, strong) NSDate *pubDate;
@property (nonatomic, strong) NSString *creator;
@property (nonatomic, strong) NSURL *enclosureURL;
@property (nonatomic, assign) BOOL isFavorited;
@property (nonatomic, strong) NSMutableSet *mediaThumbnails;
@property (nonatomic, strong) NSMutableSet *mediaContents;

@property (nonatomic, strong) NSURL *feedURL;


@end
