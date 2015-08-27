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
//  SearchDetailViewController.m
//  WhiteHouse
//

#import "WebViewController.h"
#import "GAI.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

@interface WebViewController ()

@end

@implementation WebViewController
@synthesize url;
@synthesize link;
- (void)viewDidLoad {
    [super viewDidLoad];

    _sidebarButton.target = self.revealViewController;
    _sidebarButton.action = @selector(revealToggle:);
    
    _webView.delegate = self;
    
    if (url){
        link = url;
    }else{
        link = self.title;
    }
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL: [NSURL URLWithString: link] cachePolicy: NSURLRequestUseProtocolCachePolicy timeoutInterval: 30.0];
    [_webView loadRequest: request];
    _webView.scalesPageToFit = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma activity indicator
-(void)webViewDidStartLoad:(UIWebView *)webView{
    
    [_activityind startAnimating];
    
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    
    [_activityind stopAnimating];
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"webViewLoaded"     // Event category (required)
                                                              action:@"button_press"  // Event action (required)
                                                               label:link             // Event label
                                                               value:nil] build]];    // Event value
    
}

@end
