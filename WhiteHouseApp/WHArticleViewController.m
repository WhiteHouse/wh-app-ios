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
//  WHWebViewController.m
//  WhiteHouseApp
//
//

#import "WHArticleViewController.h"

#import "WHAppDelegate.h"
#import "NIWebController.h"
#import "WHSharingUtilities.h"

@interface WHArticleViewController ()
@property (nonatomic, strong) WHSharingUtilities *sharing;
@property (nonatomic, assign) BOOL needsTemplateRendering;
@end


@implementation WHArticleViewController

@synthesize feedItem;
@synthesize webView = _webView;
@synthesize toolbar;
@synthesize sharing = _sharing;
@synthesize needsTemplateRendering;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.sharing = [[WHSharingUtilities alloc] initWithViewController:self];
        UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share)];
        shareButton.style = UIBarButtonItemStylePlain;
        self.navigationItem.rightBarButtonItem = shareButton;
    }
    return self;
}


- (void)share
{
    [self.sharing share:self.feedItem];
}


- (void)textUp
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"WhiteHouse.textUp()"];
}


- (void)textDown
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"WhiteHouse.textDown()"];
}


- (void)loadArticleContent
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterLongStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    NSString *dateString = [dateFormatter stringFromDate:self.feedItem.pubDate];
    
    NSMutableDictionary *pageInfo = [NSMutableDictionary dictionary];
    [pageInfo setObject:self.feedItem.descriptionHTML forKey:@"description"];
    [pageInfo setObject:[self.feedItem.link absoluteString] forKey:@"link"];
    [pageInfo setObject:self.feedItem.title forKey:@"title"];
    [pageInfo setObject:dateString forKey:@"date"];
    [pageInfo setObject:[NSNumber numberWithInt:[self.feedItem.pubDate timeIntervalSince1970]] forKey:@"timestamp"];
    [pageInfo setObject:self.feedItem.creator forKey:@"creator"];
    [pageInfo setObject:AppConfig(@"ArticleBaseURL") forKey:@"baseURL"];
    
    NSError *error = nil;
    NSData *pageInfoData = [NSJSONSerialization dataWithJSONObject:pageInfo options:0 error:&error];
    if (!pageInfoData) {
        NSLog(@"Could not write JSON data: %@", error);
    } else {
        NSString *pageInfoString = [[NSString alloc] initWithData:pageInfoData encoding:NSUTF8StringEncoding];
        NSString *script = [NSString stringWithFormat:@"WhiteHouse.loadPage(%@);", pageInfoString];
        [self.webView stringByEvaluatingJavaScriptFromString:script];
    }
}


- (void)loadTemplate
{
    DebugLog(@"initiating request for template");
    self.needsTemplateRendering = YES;
    NSURL *base = [[NSBundle mainBundle] URLForResource:@"post" withExtension:@"html"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:base]];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    DebugLog(@"finished loading: %@", webView.request);
    if (self.needsTemplateRendering) {
        self.needsTemplateRendering = NO;
        [self loadArticleContent];
    }
}


/**
 * Return the branding view that goes in the center of the toolbar
 */
- (UIView *)brandingView
{
    UILabel *brandingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    
    CGFloat brandingFontSize;
    if (NIIsPad()) {
        brandingFontSize = [AppConfig(@"ToolbarBranding.iPadFontSize") floatValue];
    } else {
        brandingFontSize = [AppConfig(@"ToolbarBranding.iPhoneFontSize") floatValue];
    }
    
    brandingLabel.font = [UIFont fontWithName:AppConfig(@"ToolbarBranding.FontName") size:brandingFontSize];
    brandingLabel.text = NSLocalizedString(@"ArticleBrandingText", @"Text that appears at the bottom of article views");
    brandingLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    brandingLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    brandingLabel.shadowOffset = CGSizeMake(0, -1);
    brandingLabel.backgroundColor = [UIColor clearColor];
    brandingLabel.alpha = 0.5;
    [brandingLabel sizeToFit];
    
    UIView *brandingView = [[UIView alloc] initWithFrame:brandingLabel.bounds];
    [brandingView addSubview:brandingLabel];
    
    return brandingView;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGFloat viewWidth = self.view.bounds.size.width;
    CGFloat viewHeight = self.view.bounds.size.height;
    CGFloat toolbarHeight = 44;
    
    self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, viewHeight - toolbarHeight, viewWidth, toolbarHeight)];
    self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"embiggen"] style:UIBarButtonItemStylePlain target:self action:@selector(textUp)];
    UIBarButtonItem *itemSmaller = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"shrinkify"] style:UIBarButtonItemStylePlain target:self action:@selector(textDown)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *branding = [[UIBarButtonItem alloc] initWithCustomView:[self brandingView]];
    self.toolbar.items = [NSArray arrayWithObjects:item, itemSmaller, space, branding, space, nil];
    
    [self.view addSubview:self.toolbar];
    
    // create our web view
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, viewHeight - toolbarHeight)];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    [self loadTemplate];
}


- (void)viewDidUnload
{
    self.webView.delegate = nil;
    [self.webView stopLoading];
    [super viewDidUnload];
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    DebugLog(@"request: %@", request);
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        DebugLog(@"navigation is a click");
        NIWebController *browser = [[NIWebController alloc] initWithNibName:nil bundle:nil];
        [self.navigationController pushViewController:browser animated:YES];
        [browser openURL:request.URL];
        return NO;
    }
    
    return YES;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    DebugLog(@"web view rotation...?");
    return toInterfaceOrientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

@end
