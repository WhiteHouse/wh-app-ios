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
//  WHYouTubePlayerViewController.m
//  WhiteHouseApp
//
//

#import "WHYouTubePlayerViewController.h"

@interface WHYouTubePlayerViewController ()
@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) UIWebView *webView;

// excuse the awkward name, but this literally means that the view needs to call the JS function: loadVideo
@property (nonatomic, assign) BOOL needsLoadVideo;
@end

@implementation WHYouTubePlayerViewController

@synthesize videoURL = _videoURL;
@synthesize webView;
@synthesize needsLoadVideo;

- (id)initWithVideoURL:(NSURL *)videoURL
{
    if ((self = [super initWithNibName:nil bundle:nil])) {
        self.videoURL = videoURL;
    }
    
    return self;
}


// so we don't get crashes when the UIWebView calls a deallocated delegate...
- (void)unhookWebView
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"stopVideo();"];
    [self.webView stopLoading];
    self.webView.delegate = nil;
}


- (void)dealloc
{
    [self unhookWebView];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    // initalize our webview
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.hidden = YES;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.scrollView.bounces = NO;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    NSURL *playerURL = [[NSBundle mainBundle] URLForResource:@"youtube" withExtension:@"html"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:playerURL]];
    
    self.needsLoadVideo = YES;
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // shut down the web view properly
    [self unhookWebView];
    self.webView = nil;
}


- (void)fixNavBar
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    self.view.window.rootViewController.view.frame = [UIScreen mainScreen].applicationFrame;
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}


static NSString *movieNotification = @"UIMoviePlayerControllerDidExitFullscreenNotification";


- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fixNavBar)
                                                 name:movieNotification
                                               object:nil];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:movieNotification object:nil];
}


#pragma mark UIWebViewDelegate methods


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (self.needsLoadVideo) {
        self.needsLoadVideo = NO;
        
        self.webView.hidden = NO;
        NSString *loadVideoScript = [NSString stringWithFormat:@"loadVideo(\"%@\")", self.videoURL.absoluteString];
        
        DebugLog(@"Displayed webView; calling script: %@", loadVideoScript);
        [self.webView stringByEvaluatingJavaScriptFromString:loadVideoScript];
    }
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    DebugLog(@"Request: %@", request);
    
    return YES;
}


@end
