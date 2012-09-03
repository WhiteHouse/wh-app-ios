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
//  WHFeedParser.m
//  WhiteHouseApp
//
//

#import "WHFeedParser.h"

#import "WHXMLUtils.h"


@interface WHFeedParser ()
@property (nonatomic, copy) WHFeedParserCallback callbackBlock;
@property (nonatomic, strong) NSData *feedData;
@property (nonatomic, strong) WHFeedItem *currentItem;
@property (nonatomic, strong) NSMutableArray *tagStack;
@end


@implementation WHFeedParser

@synthesize callbackBlock;
@synthesize feedData = _feedData;
@synthesize currentItem = _currentItem;
@synthesize tagStack = _tagStack;


- (id)initWithFeedData:(NSData *)feedData
{
    if ((self = [super init])) {
        self.feedData = feedData;
        self.tagStack = [NSMutableArray array];
    }
    
    return self;
}

NSRegularExpression *_tagPattern;

+ (NSRegularExpression *)tagPattern
{
    if (_tagPattern == nil) {
        _tagPattern = [NSRegularExpression regularExpressionWithPattern:@"<(/|)[^>]*>" options:0 error:nil];
    }
    return _tagPattern;
}

NSRegularExpression *_dupeSpacePattern;

+ (NSRegularExpression *)dupeSpacePattern
{
    if (_dupeSpacePattern == nil) {
        _dupeSpacePattern = [NSRegularExpression regularExpressionWithPattern:@"\\s{2,}" options:0 error:nil];
    }
    return _dupeSpacePattern;
}


- (void)parse:(WHFeedParserCallback)callback {
    self.callbackBlock = callback;
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.feedData];
    parser.delegate = self;
    [parser setShouldReportNamespacePrefixes:YES];
    [parser setShouldProcessNamespaces:NO];
    [parser parse];
}


- (NSString *)tagPath {
    NSMutableString *path = [NSMutableString string];
    for (NSDictionary *context in self.tagStack) {
        [path appendFormat:@"/%@", [context objectForKey:@"elementName"]];
    }
    return path;
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    NSDictionary *tag = [NSDictionary dictionaryWithObjectsAndKeys:
                         elementName, @"elementName",
                         [NSMutableString string], @"text",
                         attributeDict, @"attributes",
                         nil];
    // push tag onto stack
    [self.tagStack addObject:tag];
    
    if ([[self tagPath] isEqualToString:@"/rss/channel/item"]) {
        self.currentItem = [[WHFeedItem alloc] init];
    }
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [[[self.tagStack lastObject] objectForKey:@"text"] appendString:string];
}


- (WHMediaElement *)mediaElementFromAttributes:(NSDictionary *)attrs
{
    WHMediaElement *media = [WHMediaElement new];
    NSString *stringURL = [attrs objectForKey:@"url"];
    media.URL = [NSURL URLWithString:stringURL];
    media.size = CGSizeMake([[attrs objectForKey:@"width"] floatValue], [[attrs objectForKey:@"height"] floatValue]);
    media.type = [attrs objectForKey:@"type"];
    return media;
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    NSString *tagPath = [self tagPath];
    NSDictionary *context = [self.tagStack lastObject];
    NSDictionary *attrs = [context objectForKey:@"attributes"];
    NSString *text = [context objectForKey:@"text"];

    if ([tagPath isEqualToString:@"/rss/channel/item"]) {
        self.callbackBlock(self.currentItem);
        self.currentItem = nil;
    } else if ([tagPath hasSuffix:@"item/title"]) {
        self.currentItem.title = text;
    } else if ([tagPath hasSuffix:@"item/dc:creator"]) {
        self.currentItem.creator = [WHXMLUtils textFromHTMLString:text xpath:@"*"];
        if (!self.currentItem.creator) {
            self.currentItem.creator = text;
        }
        self.currentItem.creator = [[[self class] tagPattern] stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@""];
    } else if ([tagPath hasSuffix:@"item/guid"]) {
        self.currentItem.guid = text;
    } else if ([tagPath hasSuffix:@"item/description"]) {
        self.currentItem.descriptionHTML = text;
        self.currentItem.descriptionText = [WHXMLUtils textFromHTMLString:text xpath:AppConfig(@"TextExtractionXPath")];
    } else if ([tagPath hasSuffix:@"item/link"]) {
        self.currentItem.link = [NSURL URLWithString:text];
    } else if ([tagPath hasSuffix:@"item/media:thumbnail"]) {
        WHMediaElement *thumbnail = [self mediaElementFromAttributes:attrs];
        if (thumbnail.size.width) {
            [self.currentItem addMediaThumbnail:thumbnail];
        }
    } else if ([tagPath hasSuffix:@"item/media:content"]) {
        [self.currentItem addMediaContent:[self mediaElementFromAttributes:attrs]];
    } else if ([tagPath hasSuffix:@"item/enclosure"]) {
        self.currentItem.enclosureURL = [NSURL URLWithString:[[context objectForKey:@"attributes"] objectForKey:@"url"]];
    } else if ([tagPath hasSuffix:@"item/category"]) {
        NSArray *categories = self.currentItem.categories;
        if (categories) {
            self.currentItem.categories = [categories arrayByAddingObject:text];
        } else {
            self.currentItem.categories = [NSArray arrayWithObject:text];
        }
    } else if ([tagPath hasSuffix:@"item/pubDate"]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        NSLocale *locale = [[NSLocale alloc]  initWithLocaleIdentifier:@"en_US_POSIX"];
        [formatter setLocale:locale];
        [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
        self.currentItem.pubDate = [formatter dateFromString:text];
    }
    
    // pop tag off stack
    [self.tagStack removeLastObject];
}

@end
