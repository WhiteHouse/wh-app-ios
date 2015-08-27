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

#import "Post.h"
@implementation Post

- (NSString*)getDate{
    NSDateFormatter *rssDateFormatter = [[NSDateFormatter alloc] init];
    [rssDateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss ZZ"];
    NSDate *rssDate = [rssDateFormatter dateFromString:self.pubDate];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    NSString *formattedDateString = [dateFormatter stringFromDate:rssDate];

    return formattedDateString;
}

- (NSString*)getTime{
    NSDateFormatter *rssDateFormatter = [[NSDateFormatter alloc] init];
    [rssDateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss ZZ"];
    NSDate *rssDate = [rssDateFormatter dateFromString:self.pubDate];
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"h:mm a"];
    NSString *formattedTimeString = [timeFormatter stringFromDate: rssDate];
    
    return formattedTimeString;
}


+(NSString*)todayYesterdayOrDate:(NSString*)s{
    NSDateFormatter *rssDateFormatter = [[NSDateFormatter alloc] init];
    [rssDateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss ZZ"];
    NSDate *rssDate = [rssDateFormatter dateFromString:s];
    NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
    [dayFormatter setDateFormat:@"dd MMM yyyy"];
    NSString *todayString = [dayFormatter stringFromDate: [NSDate date]];
    NSString *yesterdayString = [dayFormatter stringFromDate: [[NSDate date]dateByAddingTimeInterval:((-60*60)*24)]];
    NSString *comparedString = [dayFormatter stringFromDate: rssDate];
    
    if([todayString isEqualToString:comparedString]) {
        return @"Today";
    }else if([yesterdayString isEqualToString:comparedString]){
        return @"Yesterday";
    }else{
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        NSString *formattedDateString = [dateFormatter stringFromDate:rssDate];
        return formattedDateString;
    }
}

+ (NSString *)stringByStrippingHTML:(NSString*)str
{
    NSRange r;
    while ((r = [str rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
    {
        str = [str stringByReplacingCharactersInRange:r withString:@""];
        str = [str stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        str = [str stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
        str = [str stringByReplacingOccurrencesOfString:@"&mdash;" withString:@"-"];
        str = [str stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
        str = [str stringByReplacingOccurrencesOfString:@"&ldquo;" withString:@"\""];
        str = [str stringByReplacingOccurrencesOfString:@"&rdquo;" withString:@"\""];
        str = [str stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
        str = [str stringByReplacingOccurrencesOfString:@"&rsquo;" withString:@"'"];
    }
    return str;
}
+ (Post *)postFromDictionary:(NSDictionary*)dict{
    Post *post = [[Post alloc]init];
    post.type = [dict objectForKey:@"type"];
    post.title = [dict objectForKey:@"title"];
    post.creator = [dict objectForKey:@"creator"];
    post.pageDescription = [dict objectForKey:@"pageDescription"];
    post.link = [dict objectForKey:@"url"];
    post.video = [dict objectForKey:@"video"];
    post.pubDate = [dict objectForKey:@"pubDate"];
    post.iPadThumbnail = [dict objectForKey:@"iPadThumbnail"];
    post.mobile2048 = [dict objectForKey:@"mobile2048"];
    return post;
}
+ (NSDictionary *)dictionaryFromPost:(Post*)post{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:post.type forKey:@"type"];
    [dict setValue:post.title forKey:@"title"];
    [dict setValue:post.link forKey:@"url"];
    [dict setValue:post.video forKey:@"video"];
    [dict setValue:post.pageDescription forKey:@"pageDescription"];
    [dict setValue:post.iPadThumbnail forKey:@"iPadThumbnail"];
    [dict setValue:post.pubDate forKey:@"pubDate"];
    [dict setValue:post.creator forKey:@"creator"];
    [dict setValue:post.mobile2048 forKey:@"mobile2048"];
    return dict;
}

+ (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate
{
    if ([date compare:beginDate] == NSOrderedAscending)
        return NO;
    
    if ([date compare:endDate] == NSOrderedDescending)
        return NO;
    
    return YES;
}

@end
