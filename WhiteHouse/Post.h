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

#import <Foundation/Foundation.h>

@interface Post : NSObject

@property (strong, nonatomic) NSString * type;
@property (strong, nonatomic) NSString * title;
@property (strong, nonatomic) NSString * pubDate;
@property (strong, nonatomic) NSString * link;
@property (strong, nonatomic) NSString * creator;
@property (strong, nonatomic) NSString * pageDescription;
@property (strong, nonatomic) NSString * collectionThumbnail;
@property (strong, nonatomic) NSString * iPhoneThumbnail;
@property (strong, nonatomic) NSString * iPadThumbnail;
@property (strong, nonatomic) NSString * video;
@property (strong, nonatomic) NSString * mobile1024;
@property (strong, nonatomic) NSString * mobile2048;
- (NSString*)getDate;
- (NSString*)getTime;
+ (NSString*)todayYesterdayOrDate:(NSString*)s;
+ (NSString *)stringByStrippingHTML:(NSString*)str;
+ (Post *)postFromDictionary:(NSDictionary*)dict;
+ (NSDictionary *)dictionaryFromPost:(Post*)p;
+ (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate;
@end
