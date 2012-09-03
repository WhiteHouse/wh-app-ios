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
//  WHSearchController.m
//  WhiteHouseApp
//
//

#import "WHSearchController.h"

@interface WHSearchController ()
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, assign) int page;
@end

@implementation WHSearchController
@synthesize query;
@synthesize delegate = _delegate;
@synthesize results = _results;

@synthesize queue;
@synthesize page;


- (id)initWithDelegate:(id <WHSearchControllerDelegate>)delegate
{
    if ((self = [super init])) {
        self.delegate = delegate;
        self.queue = [NSOperationQueue new];
        self.queue.maxConcurrentOperationCount = 1;
        self.page = 0;
    }
    
    return self;
}


- (void)reportError:(NSError *)error
{
    DebugLog(@"Error in search: %@", error.localizedDescription);
    [self.delegate searchController:self didFailWithError:error];
}


+ (NSString *)escapeQueryParameter:(NSString *)param
{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)param, NULL, (CFStringRef)@"&: _=-?!%", kCFStringEncodingUTF8));
}


- (void)fetchResults
{
    self.page = self.page + 1;
    
    NSString *formatString = AppConfig(@"SearchURLFormat");
    NSString *escaped = [[self class] escapeQueryParameter:query];
    NSURL *searchURL = [NSURL URLWithString:[NSString stringWithFormat:formatString, escaped, self.page]];
    
    DebugLog(@"Search URL = %@", searchURL);
    NINetworkRequestOperation *op = [[NINetworkRequestOperation alloc] initWithURL:searchURL];
    
    // this block will be called with the operation itself
    op.didFinishBlock = ^(id obj) {
        // cast it to access network-op-specific properties
        id result = [NSJSONSerialization JSONObjectWithData:op.data options:0 error:nil];
        DebugLog(@"API result = %@", result);
        id results = [result objectForKey:@"results"];
        if (results && [results respondsToSelector:@selector(objectAtIndex:)]) {
            if (self.results) {
                self.results = [self.results arrayByAddingObjectsFromArray:results];
            } else {
                self.results = results;
            }
            [self.delegate searchControllerDidFindResults:self];
        }
    };
    
    op.didFailWithErrorBlock = ^(id obj, NSError *error) {
        [self reportError:error];
    };
    
    // the operation will start when added to the queue
    [self.queue addOperation:op];
}


@end
