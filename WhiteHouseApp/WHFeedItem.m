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
//  WHFeedItem.m
//  WhiteHouseApp
//
//

#import "WHFeedItem.h"

#import "WHXMLUtils.h"

////////////////////////////////////////////////////////////
// WHMediaElement
////////////////////////////////////////////////////////////

@implementation WHMediaElement
@synthesize size;
@synthesize URL;
@synthesize medium;
@synthesize type;


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeCGSize:self.size forKey:@"size"];
    [aCoder encodeObject:self.URL forKey:@"URL"];
    [aCoder encodeObject:self.medium forKey:@"medium"];
    [aCoder encodeObject:self.type forKey:@"type"];
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super init])) {
        self.size = [aDecoder decodeCGSizeForKey:@"size"];
        self.URL = [aDecoder decodeObjectForKey:@"URL"];
        self.medium = [aDecoder decodeObjectForKey:@"medium"];
        self.type = [aDecoder decodeObjectForKey:@"type"];
    }
    return self;
}


@end


////////////////////////////////////////////////////////////
// WHFeedItem
////////////////////////////////////////////////////////////


@implementation WHFeedItem

@synthesize title;
@synthesize guid;
@synthesize link;
@synthesize descriptionHTML;
@synthesize descriptionText;
@synthesize categories;
@synthesize pubDate;
@synthesize creator;
@synthesize mediaThumbnails;
@synthesize mediaContents;
@synthesize enclosureURL;
@synthesize isFavorited;
@synthesize feedURL;

- (id)init
{
    if ((self = [super init])) {
        self.mediaContents = [NSMutableSet set];
        self.mediaThumbnails = [NSMutableSet set];
    }
    
    return self;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"<WHFeedItem guid: %@; title: %@; pubDate: %@>", self.guid, self.title, self.pubDate];
}


#define ENCODE_PROPERTY(name) [aCoder encodeObject:self.name forKey:@#name]

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    ENCODE_PROPERTY(title);
    ENCODE_PROPERTY(guid);
    ENCODE_PROPERTY(link);
    ENCODE_PROPERTY(descriptionText);
    ENCODE_PROPERTY(descriptionHTML);
    ENCODE_PROPERTY(categories);
    ENCODE_PROPERTY(pubDate);
    ENCODE_PROPERTY(creator);
    ENCODE_PROPERTY(mediaThumbnails);
    ENCODE_PROPERTY(mediaContents);
    ENCODE_PROPERTY(enclosureURL);
    ENCODE_PROPERTY(feedURL);
    [aCoder encodeObject:@(self.isFavorited) forKey:@"isFavorited"];
}

#define DECODE_PROPERTY(name) self.name = [aDecoder decodeObjectForKey:@#name]

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super init])) {
        DECODE_PROPERTY(title);
        DECODE_PROPERTY(guid);
        DECODE_PROPERTY(link);
        DECODE_PROPERTY(descriptionText);
        
        NSString *oldItemDescription = [aDecoder decodeObjectForKey:@"itemDescription"];
        if (oldItemDescription) {
            self.descriptionHTML = oldItemDescription;
            self.descriptionText = [WHXMLUtils textFromHTMLString:oldItemDescription xpath:@"//p"];
        } else {
            DECODE_PROPERTY(descriptionHTML);
            DECODE_PROPERTY(descriptionText);
        }
        
        DECODE_PROPERTY(categories);
        DECODE_PROPERTY(pubDate);
        DECODE_PROPERTY(creator);
        DECODE_PROPERTY(mediaThumbnails);
        DECODE_PROPERTY(mediaContents);
        DECODE_PROPERTY(enclosureURL);
        DECODE_PROPERTY(feedURL);
        self.isFavorited = [[aDecoder decodeObjectForKey:@"isFavorited"] boolValue];
    }
    return self;
}


- (void)addMediaThumbnail:(WHMediaElement *)media
{
    if (!self.mediaThumbnails) {
        self.mediaThumbnails = [NSMutableSet set];
    }
    
    [self.mediaThumbnails addObject:media];
}


- (void)addMediaContent:(WHMediaElement *)media
{
    if (!self.mediaContents) {
        self.mediaContents = [NSMutableSet set];
    }
    
    [self.mediaContents addObject:media];
}


- bestMediaElement:(id <NSFastEnumeration>)collection forWidth:(CGFloat)width
{
    CGFloat pixelWidth = width * [UIScreen mainScreen].scale;
    
    WHMediaElement *closest = nil;
    for (WHMediaElement *media in collection) {
        CGFloat mediaDiff = ABS(pixelWidth - media.size.width);
        CGFloat closestDiff = ABS(pixelWidth - closest.size.width);
        if (closest == nil) {
            closest = media;
        } else if (mediaDiff < closestDiff) {
            closest = media;
        } else if (mediaDiff == closestDiff && closest.size.width < media.size.width) {
            closest = media;
        }
    }
    
    DebugLog(@"looking for match for %i; found %i", (int)pixelWidth, (int)closest.size.width);
    
    return closest;   
}


- (WHMediaElement *)bestThumbnailForWidth:(CGFloat)width
{
    return [self bestMediaElement:self.mediaThumbnails forWidth:width];
}


- (WHMediaElement *)bestContentForWidth:(CGFloat)width
{
    return [self bestMediaElement:self.mediaContents forWidth:width];
}


- (NSString *)trackingPathCompontent
{
    if (self.title) {
        return self.title;
    } else if (self.guid) {
        return self.guid;
    } else {
        return @"(unknown)";
    }
}


- (BOOL)isMovie
{
    return self.enclosureURL != nil;
}


#pragma mark Equality testing


- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return [self isEqualToFeedItem:object];
    }
    
    return NO;
}


- (NSUInteger)hash
{
    return [self.guid hash];
}


- (BOOL)isEqualToFeedItem:(WHFeedItem *)other
{
    if (self == other) {
        return YES;
    }
    
    return [self.guid isEqualToString:other.guid];
}


@end
