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
//  WHRemoteFile.m
//  WhiteHouseApp
//
//

#import "WHRemoteFile.h"

#import <CommonCrypto/CommonDigest.h>

@implementation WHRemoteFile

@synthesize bundlePath = _bundlePath;
@synthesize remoteURL = _remoteURL;

- (id)initWithBundleResource:(NSString *)name ofType:(NSString *)extension remoteURL:(NSURL *)remoteURL
{
    if ((self = [super init])) {
        _queue = dispatch_queue_create(NSStringFromClass([self class]).UTF8String, NULL);
        if (name && extension) {
            self.bundlePath = [[NSBundle mainBundle] pathForResource:name ofType:extension];
        }
        self.remoteURL = remoteURL;
    }
    
    return self;
}


- (NSString *)cacheDirectoryPath
{
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSArray *appSupportURLs = [fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    NSURL *directoryURL = [appSupportURLs objectAtIndex:0];
    NSString *directoryPath = [directoryURL path];
    if (![fm fileExistsAtPath:directoryPath]) {
        DebugLog(@"Creating app support directory");
        [fm createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return directoryPath;
}


- (NSString *)localCachePath
{
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    NSData *data = [[self.remoteURL absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA1(data.bytes, data.length, digest);
    NSMutableString *filename = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int ii = 0; ii < CC_SHA1_DIGEST_LENGTH; ii++) {
        [filename appendFormat:@"%02x", digest[ii]];
    }
    
    DebugLog(@"SHA1(%@) = %@", self.remoteURL, filename);
    
    return [[self cacheDirectoryPath] stringByAppendingPathComponent:filename];
}


- (NSData *)data
{
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *cachePath = [self localCachePath];
    if ([fm fileExistsAtPath:cachePath]) {
        return [NSData dataWithContentsOfFile:cachePath];
    } else if([fm fileExistsAtPath:self.bundlePath]) {
        return [NSData dataWithContentsOfFile:self.bundlePath];
    } else {
        return nil;
    }
}


- (void)updateWithValidator:(ValidatorBlock)validator
{
    dispatch_async(_queue, ^{
        NINetworkActivityTaskDidStart();
        NSData *data = [NSData dataWithContentsOfURL:self.remoteURL];
        if (data && validator(data)) {
            [data writeToFile:[self localCachePath] atomically:YES];
        }
        NINetworkActivityTaskDidFinish();
    });
}


@end
