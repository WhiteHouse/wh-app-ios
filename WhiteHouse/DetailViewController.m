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
//  DetailViewController.m
//  WhiteHouse
//

#import "DetailViewController.h"
#import "FavoritesViewController.h"
#import "Social/Social.h"
#import <CoreLocation/CoreLocation.h>
#import "GAI.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "LiveViewController.h"


@interface DetailViewController ()
@property (weak, nonatomic) NSString *favoriteButtonTitle;
@property (nonatomic, assign) const float heightCon;
@property (nonatomic, strong) UIView *baseView;
@end

@implementation DetailViewController
@synthesize post;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    _webView.delegate = self;
    _webView.scalesPageToFit = YES;
    
    self.title = post.title;
    
    // load the template
    NSString *cssPath = [[NSBundle mainBundle] pathForResource:@"wh" ofType:@"css"];
    NSString *cssFile = [NSString stringWithContentsOfFile:cssPath encoding:NSUTF8StringEncoding error:nil];
    NSMutableString *css = [NSMutableString stringWithString:cssFile];
    NSString *underscorePath = [[NSBundle mainBundle] pathForResource:@"underscore-min" ofType:@"js"];
    NSString *underscoreFile = [NSString stringWithContentsOfFile:underscorePath encoding:NSUTF8StringEncoding error:nil];
    NSMutableString *underscore = [NSMutableString stringWithString:underscoreFile];
    NSString *zeptoPath = [[NSBundle mainBundle] pathForResource:@"zepto.min" ofType:@"js"];
    NSString *zeptoFile = [NSString stringWithContentsOfFile:zeptoPath encoding:NSUTF8StringEncoding error:nil];
    NSMutableString *zepto = [NSMutableString stringWithString:zeptoFile];
    NSString *jsPath = [[NSBundle mainBundle] pathForResource:@"wh" ofType:@"js"];
    NSString *jsFile = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:nil];
    NSMutableString *js = [NSMutableString stringWithString:jsFile];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"post" ofType:@"html"];
    NSString *template = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSMutableString *html = [NSMutableString stringWithString:template];
    
    // make substitutions
    [html replaceOccurrencesOfString:@"[[[css]]]" withString:css options:NSLiteralSearch range:NSMakeRange(0, html.length)];
    [html replaceOccurrencesOfString:@"[[[js]]]" withString:js options:NSLiteralSearch range:NSMakeRange(0, html.length)];
    [html replaceOccurrencesOfString:@"[[[zepto]]]" withString:zepto options:NSLiteralSearch range:NSMakeRange(0, html.length)];
    [html replaceOccurrencesOfString:@"[[[underscore]]]" withString:underscore options:NSLiteralSearch range:NSMakeRange(0, html.length)];
    [html replaceOccurrencesOfString:@"[[[title]]]" withString:post.title options:NSLiteralSearch range:NSMakeRange(0, html.length)];
    [html replaceOccurrencesOfString:@"[[[creator]]]" withString:post.creator options:NSLiteralSearch range:NSMakeRange(0, html.length)];
    
    if (post.getDate){
        [html replaceOccurrencesOfString:@"[[[date]]]" withString:post.getDate options:NSLiteralSearch range:NSMakeRange(0, html.length)];
    }else {
        [html replaceOccurrencesOfString:@"[[[date]]]" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, html.length)];
    }
    [html replaceOccurrencesOfString:@"[[[description]]]" withString:post.pageDescription options:NSLiteralSearch range:NSMakeRange(0, html.length)];
    [_webView loadHTMLString:html baseURL:nil];

    
    FavoritesViewController * favoriteController = [[FavoritesViewController alloc] init];
    if ([favoriteController isFavorited:post]){
        _favoriteButtonTitle = @"Unfavorite";
    }else{
        _favoriteButtonTitle = @"Favorite";
    }
    self.edgesForExtendedLayout = UIRectEdgeNone;
    UIEdgeInsets insets;
    if (IS_IOS_8_OR_LATER) {
        if (_liveBanner){
            insets = UIEdgeInsetsMake(30, 0, 0, 0);
            self.webView.scrollView.contentInset = insets;
        }
    }else{
        if (_liveBanner){
            insets = UIEdgeInsetsMake(15, 10, 0, 10);
            self.webView.scrollView.contentInset = insets;
        }else {
            insets = UIEdgeInsetsMake(0, 10, 0, 10);
            self.webView.scrollView.contentInset = insets;
        }
    }
    [self createBanner];}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"detailViewLoaded"     // Event category (required)
                                                          action:@"button_press"  // Event action (required)
                                                           label:post.link          // Event label
                                                           value:nil] build]];    // Event value
}

-(void) viewWillDisappear:(BOOL)animated{
    [self.baseView removeFromSuperview];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self createBanner];
    
}

-(void)createBanner{
    [self.baseView removeFromSuperview];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.livePosts){
        NSMutableArray *happeningNow = [[NSMutableArray alloc]init];
        for (NSDictionary *d in appDelegate.livePosts) {
            Post *livePost = [Post postFromDictionary:d];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss ZZZ";
            NSDate *postDate = [formatter dateFromString: livePost.pubDate];
            NSDate *postDateEnd = [postDate dateByAddingTimeInterval:(+30*60)];
            NSDate *timeNow = [NSDate date];
            
            if([Post date:timeNow isBetweenDate:postDate andDate:postDateEnd]){
                [happeningNow addObject:livePost];
            }
        }
        if ([happeningNow count] > 0){
            NSString *msg = [[NSString alloc] init];
            UILabel *liveEventsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, self.view.frame.size.width, 20)];
            if ([happeningNow count] == 1){
                msg = [NSString stringWithFormat: @"Live: %@", [[happeningNow firstObject] title]];
                liveEventsLabel.text = [NSString stringWithFormat:@"%@", msg];
            }else {
                msg = @"Live events. Watch Live";
                liveEventsLabel.text = [NSString stringWithFormat:@"%ld %@", (unsigned long)[happeningNow count], msg];
            }
            
            UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
            float frameWidth;
            if (orientation == UIDeviceOrientationPortrait || IS_IOS_8_OR_LATER){
                frameWidth = self.view.frame.size.width;
            }else {
                if (self.view.frame.size.width > self.view.frame.size.height)
                    frameWidth = self.view.frame.size.width;
                else
                    frameWidth = self.view.frame.size.height;
            }
            
            if (IS_IOS_8_OR_LATER)
                self.heightCon = (self.view.bounds.size.height > self.view.bounds.size.width)? 64 : 32;
            else{
                if(orientation == UIDeviceOrientationPortrait){
                    self.heightCon = 64;
                }
                else
                    self.heightCon = 52;
            }
            if([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPad)
                _baseView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, frameWidth, 30)];
            else
                _baseView = [[UIView alloc] initWithFrame:CGRectMake(0, _heightCon, frameWidth, 30)];
            liveEventsLabel.textAlignment = NSTextAlignmentCenter;
            liveEventsLabel.textColor = [UIColor whiteColor];
            [_baseView addSubview:liveEventsLabel];
            _baseView.backgroundColor = [UIColor colorWithRed:0.90 green:0.57 blue:0.22 alpha:0.9];
            [self.view addSubview:_baseView];
            [self.navigationController.view addSubview:_baseView];
            _baseView.userInteractionEnabled = YES;
            UITapGestureRecognizer *tapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(presentLiveViewController)];
            [_baseView addGestureRecognizer:tapGesture];
        }
    }
}

-(void)presentLiveViewController{
    [self.navigationController popToRootViewControllerAnimated:YES]; //Fixed crashing issue on iOS 8
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle: nil];
    
    LiveViewController *mainVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"LiveViewController"];
    UINavigationController *navVC =[[UINavigationController alloc]    initWithRootViewController:mainVC];
    [self.revealViewController setFrontViewController:navVC];
}

- (IBAction)showActionSheet:(id)sender {
   
    UIAlertAction *favoriteAction = [UIAlertAction
                                   actionWithTitle:_favoriteButtonTitle
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                       [self toggleFavorite];
                                       
                                   }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction * action)
                                   {
                                       [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
                                       
                                   }];
    UIAlertAction *facebookAction = [UIAlertAction
                                   actionWithTitle:@"Share on Facebook"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                       [self shareFacebook];
                                   }];
    UIAlertAction *twitterAction = [UIAlertAction
                                     actionWithTitle:@"Share on Twitter"
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction * action)
                                     {
                                         [self shareTwitter];
                                         
                                     }];
    UIAlertAction *emailAction = [UIAlertAction
                                    actionWithTitle:@"Share via e-mail"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action)
                                    {
                                        [self shareEmail];
                                        
                                    }];
    if([UIAlertController class]){
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Actions"
                                              message:@"Share or save this page"
                                              preferredStyle:UIAlertControllerStyleActionSheet];
        [alertController addAction:favoriteAction];
        [alertController addAction:facebookAction];
        [alertController addAction:twitterAction];
        [alertController addAction:emailAction];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
        alertController.popoverPresentationController.barButtonItem = _actionButton;
    }else{
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:_favoriteButtonTitle, @"Share on Facebook", @"Share on Twitter", @"Share via e-mail", nil];
        
        [actionSheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self toggleFavorite];
            break;
        case 1:
            [self shareFacebook];
            break;
        case 2:
            [self shareTwitter];
            break;
        case 3:
            [self shareEmail];
            break;
        default:
            break;
    }
}

- (void) shareFacebook
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        SLComposeViewController *fbPostSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [fbPostSheet setInitialText:post.link];
        [self presentViewController:fbPostSheet animated:YES completion:nil];
    } else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"You can't post right now, make sure your device has an internet connection and you have at least one facebook account setup"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void) shareTwitter
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweetSheet setInitialText:post.link];
        [self presentViewController:tweetSheet animated:YES completion:nil];
        
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

-(void) shareEmail
{
    NSString *emailTitle = @"Sent from the White House iOS App";
    NSString *messageBody = post.link;
    //                                        NSArray *toRecipents = [NSArray arrayWithObject:@"ryan@example.com"];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    //                                        [mc setToRecipients:toRecipents];
    
    // Present mail view controller on screen
    [self presentViewController:mc animated:YES completion:NULL];
}

-(void) toggleFavorite{
    FavoritesViewController * favoriteController = [[FavoritesViewController alloc] init];
    if ([favoriteController isFavorited:post]){
        [favoriteController removeFavoritesObject:post];
        _favoriteButtonTitle = @"Favorite";
    }else{
        [favoriteController addFavoritesObject:post];
        _favoriteButtonTitle = @"Unfavorite";
    }

}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

# pragma activity indicator
-(void)webViewDidStartLoad:(UIWebView *)webView{
    
    [_activityind startAnimating];
    
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    
    [_activityind stopAnimating];
}

@end
