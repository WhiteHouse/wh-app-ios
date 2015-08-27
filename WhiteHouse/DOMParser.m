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

#import "DOMParser.h"
#import "Post.h"
#import "RXMLElement.h"

@interface DOMParser()

@property (strong, nonatomic) NSMutableString * xmlText;

@end

@implementation DOMParser

-(NSArray *) parseFeed
{
    
    NSMutableArray * posts = [[NSMutableArray alloc]init];
    if (self.xml)
    {
        RXMLElement * rss = [RXMLElement elementFromXMLData:[self.xml dataUsingEncoding:NSUTF8StringEncoding]];
        RXMLElement *root = [rss child:@"channel"];
        NSArray * elements = [root children:@"item"];
        for (RXMLElement * currentElement in elements)
        {
            Post * post = [[Post alloc] init];
            post.title = [currentElement child:@"title"].text;
            post.link = [currentElement child:@"link"].text;
            post.creator = [currentElement child:@"creator"].text;
            post.pubDate = [currentElement child:@"pubDate"].text;
            post.pageDescription = [currentElement child:@"description"].text;
            post.video = [[currentElement child:@"enclosure"] attribute:@"url"];
            NSArray *pictures = [currentElement children:@"thumbnail"];
            for (RXMLElement * picture in pictures){
                if ([[picture attribute:@"width"] isEqualToString:@"280"]){
                    post.collectionThumbnail = [[picture attribute:@"url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }else if ([[picture attribute:@"width"] isEqualToString:@"320"]){
                    post.iPhoneThumbnail = [[picture attribute:@"url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }else if ([[picture attribute:@"width"] isEqualToString:@"640"]){
                    post.iPadThumbnail = [[picture attribute:@"url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }
            }
            NSArray *content = [currentElement children:@"content"];
            for (RXMLElement * picture in content){
                if ([[picture attribute:@"width"] isEqualToString:@"640"]){
                    post.iPadThumbnail = [[picture attribute:@"url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }else if ([[picture attribute:@"width"] isEqualToString:@"1024"]){
                    post.mobile1024 = [[picture attribute:@"url"]stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }else if ([[picture attribute:@"width"] isEqualToString:@"2048"]){
                    post.mobile2048 = [[picture attribute:@"url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }
            }
            [posts addObject:post];
        }
        
    }
    return posts;
}

- (NSArray*)sectionPosts:(NSArray*)posts{
    NSMutableArray * sortedPosts = [[NSMutableArray alloc]init];
    NSString *prevDate = [[NSString alloc] init];
    NSMutableArray * subPosts = [[NSMutableArray alloc]init];
    for (Post *post in posts) {
        if ([[self getDate:post.pubDate] isEqualToString:prevDate]){
            [subPosts addObject:post];
        }else{
            if (prevDate.length>0) {
                NSArray* tmpArray = [[NSArray alloc] initWithArray:subPosts];
                if (tmpArray.count>0){
                    [sortedPosts addObject:tmpArray];
                }
                [subPosts removeAllObjects];
                [subPosts addObject:post];
            }
        }
        prevDate = [self getDate:post.pubDate];
    }
    
    return sortedPosts;
}

- (NSMutableArray*)sectionPostsByToday:(NSArray*)posts{
    NSMutableArray *postsToday =[[NSMutableArray alloc] init];
    NSMutableArray *postsUpcoming =[[NSMutableArray alloc] init];
    NSMutableArray *postsPrior =[[NSMutableArray alloc] init];
    NSMutableArray *sortedPosts = [[NSMutableArray alloc]init];
    [sortedPosts addObject:postsToday];
    [sortedPosts addObject:postsUpcoming];
    [sortedPosts addObject:postsPrior];
    for (Post *post in posts) {
        NSDateFormatter *rssDateFormatter = [[NSDateFormatter alloc] init];
        [rssDateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss ZZ"];
        NSDate *rssDate = [rssDateFormatter dateFromString:post.pubDate];
        NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
        [dayFormatter setDateFormat:@"dd MMM yyyy"];
        NSString *todayString = [dayFormatter stringFromDate: [NSDate date]];
        NSString *otherString = [dayFormatter stringFromDate: rssDate];
        BOOL isToday = false;
        if([todayString isEqualToString:otherString]) {
            isToday = true;
        }
        
        NSDate *currentTime = [NSDate date];
        NSComparisonResult result;
        result = [rssDate compare:currentTime];
        if (!isToday && result == NSOrderedDescending){
            [[sortedPosts objectAtIndex:1] addObject:post];
        }else if(isToday){
            [[sortedPosts objectAtIndex:0] addObject:post];
        }
        else {
            [[sortedPosts objectAtIndex:2] addObject: post];
        }
    }
    return sortedPosts;
}

- (int)upcomingPostCount:(NSArray*)posts{
    int postsUpcoming = 0;
    for (NSDictionary *d in posts) {
        Post *post = [Post postFromDictionary:d];
        NSDateFormatter *rssDateFormatter = [[NSDateFormatter alloc] init];
        [rssDateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss ZZ"];
        NSDate *rssDate = [rssDateFormatter dateFromString:post.pubDate];
        NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
        [dayFormatter setDateFormat:@"dd MMM yyyy"];
        NSString *todayString = [dayFormatter stringFromDate: [NSDate date]];
        NSString *otherString = [dayFormatter stringFromDate: rssDate];
        BOOL isToday;
        if([todayString isEqualToString:otherString]) {
            isToday = true;
        }
        
        NSDate *currentTime = [NSDate date];
        NSComparisonResult result;
        result = [rssDate compare:currentTime];
        if (!isToday && result == NSOrderedDescending){
            postsUpcoming += 1;
        }else if(isToday){
            postsUpcoming += 1;
        }
    }
    return postsUpcoming;
}

- (NSString*)getDate:(NSString*)date{
    NSDateFormatter *rssDateFormatter = [[NSDateFormatter alloc] init];
    [rssDateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss ZZ"];
    NSDate *rssDate = [rssDateFormatter dateFromString:date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    NSString *formattedDateString = [dateFormatter stringFromDate:rssDate];
    
    return formattedDateString;
}

@end
