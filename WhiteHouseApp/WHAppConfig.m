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
//  WHAppConfig.m
//  WhiteHouseApp
//
//

#import "WHAppConfig.h"


static WHAppConfig *sharedInstance;


@interface WHAppConfig ()
@property (nonatomic, strong) NSDictionary *config;
@end


@implementation WHAppConfig

@synthesize config;


- (id)init
{
    if ((self = [super init])) {
        NSString *configPath = [[NSBundle mainBundle] pathForResource:@"AppConfig" ofType:@"plist"];
        NSData *data = [NSData dataWithContentsOfFile:configPath];
        NSPropertyListFormat format;
        NSString *errorDescription;
        NSDictionary *configObject = [NSPropertyListSerialization propertyListFromData:data
                                                                      mutabilityOption:NSPropertyListImmutable
                                                                                format:&format
                                                                      errorDescription:&errorDescription];
        
        if (configObject) {
            self.config = configObject;
        } else {
            NSLog(@"Error reading config plist (%@): %@", configPath, errorDescription);
        }
    }
    return self;
}


+ (WHAppConfig *)sharedAppConfig
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WHAppConfig alloc] init];
    });
    
    return sharedInstance;
}


- (id)objectForKey:(NSString *)key
{
    id result = [self.config objectForKey:key];
    if (!result) {
        [NSException raise:NSGenericException format:@"No value found for config key: %@", key];
    }
    return result;
}


@end


@implementation UIColor (strings)

+ (UIColor *)colorFromRGBHexString:(NSString *)colorString
{
    if (colorString.length == 7) {
        const char *colorUTF8String = [colorString UTF8String];
        int r, g, b;
        sscanf(colorUTF8String, "#%2x%2x%2x", &r, &g, &b);
        return [UIColor colorWithRed:(r / 255.0) green:(g / 255.0) blue:(b / 255.0) alpha:1.0];
    }
    
    return nil;
}

@end
