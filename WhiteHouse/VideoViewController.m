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
//  VideoViewController.m
//  WhiteHouse
//

#import "VideoViewController.h"
#import "DOMParser.h"
#import "UIKit+AFNetworking.h"
#import "Post.h"
#import "PostTableCell.h"
#import "PostCollectionCell.h"
#import "AppDelegate.h"
#import "LiveViewController.h"
#import "Social/Social.h"
#import "FavoritesViewController.h"
#import "Constants.h"

@interface VideoViewController ()
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSArray *arrBlogData;
@property (nonatomic, strong) NSArray *arrBlogDataUnsorted;
@property (nonatomic, assign) const float heightCon;
@property (nonatomic, strong) UIView *baseView;
@property (weak, nonatomic) NSString *favoriteButtonTitle;

-(void)refreshData;
-(void)performNewFetchedDataActionsWithDataArray:(NSArray *)dataArray;
@end

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _sidebarButton.target = self.revealViewController;
    _sidebarButton.action = @selector(revealToggle:);
    
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    [self.tblVideos setDelegate:self];
    [self.tblVideos setDataSource:self];
    [self.collectBlogs setDelegate:self];
    [self.collectBlogs setDataSource:self];
    [self.collectBlogsPlus setDelegate:self];
    [self.collectBlogsPlus setDataSource:self];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    
    [self.refreshControl addTarget:self
                            action:@selector(hardRefresh)
                  forControlEvents:UIControlEventValueChanged];
    self.tblVideos.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    self.view.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    
    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType isEqualToString:@"iPad"]){
        [self.collectBlogs addSubview:self.refreshControl];
    }else{
        [self.tblVideos addSubview:self.refreshControl];
    }
    [self refreshData];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self createBanner];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self refreshData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)hardRefresh{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.videoData removeAllObjects];
    [self refreshData];
}

-(void)refreshData{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    DOMParser * parser = [[DOMParser alloc] init];
    NSArray * posts;
    NSArray * sectionedPosts;
    if(appDelegate.videoData.count > 0){
        _arrBlogDataUnsorted = appDelegate.videoData;
        sectionedPosts = [parser sectionPosts:appDelegate.videoData];
    }else{
        NSURL *url = [[NSURL alloc] initWithString:appDelegate.activeFeed];
        parser.xml = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        posts = [parser parseFeed];
        _arrBlogDataUnsorted = posts;
        sectionedPosts = [parser sectionPosts:posts];
    }
    [self performNewFetchedDataActionsWithDataArray:sectionedPosts];
    [self.refreshControl endRefreshing];
}

-(void)performNewFetchedDataActionsWithDataArray:(NSArray *)dataArray{
    if (self.arrBlogData != nil) {
        self.arrBlogData = nil;
    }
    self.arrBlogData = [[NSArray alloc] initWithArray:dataArray];
    [self.tblVideos reloadData];
    [_collectBlogs reloadData];
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return _arrBlogData.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *posts = _arrBlogData[section];
    Post *post = [posts firstObject];
    return [Post todayYesterdayOrDate:post.pubDate];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray *posts = _arrBlogData[section];
    return posts.count;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = nil;
    NSArray *set = [_arrBlogData objectAtIndex:indexPath.section];
    Post *post = [set objectAtIndex:indexPath.row];
    cell = [tableView dequeueReusableCellWithIdentifier:@"VideoCell" forIndexPath:indexPath];
    PostTableCell *videoCell = (PostTableCell *)cell;
    [videoCell.backgroundImage setImageWithURL:[NSURL URLWithString:post.iPhoneThumbnail] placeholderImage:[UIImage imageNamed:@"WH_logo_3D_CMYK.png"]];
    videoCell.titleLabel.text = post.title;
    videoCell.dateLabel.text = post.getDate;
    videoCell.card.layer.shadowColor = [UIColor blackColor].CGColor;
    videoCell.card.layer.shadowRadius = 1;
    videoCell.card.layer.shadowOpacity = 0.2;
    videoCell.card.layer.shadowOffset = CGSizeMake(0.2, 2);
    videoCell.card.layer.masksToBounds = NO;
    
    [cell setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showActionSheet:)];
    [cell addGestureRecognizer:longPress];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSArray *set = [self.arrBlogData objectAtIndex:indexPath.section];
    Post *post = [set objectAtIndex:indexPath.row];
    NSURL *fileURL = [NSURL URLWithString:post.video];
    
    _moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:fileURL];
    _moviePlayerController.controlStyle = MPMovieControlStyleDefault;
    _moviePlayerController.shouldAutoplay = YES;
    [self.view addSubview:_moviePlayerController.view];
    [_moviePlayerController setFullscreen:YES animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        [_moviePlayerController.view setFrame:CGRectMake(0, 70, 320, 270)];
    } else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        [_moviePlayerController.view setFrame:CGRectMake(0, 0, 480, 320)];
    }
    return YES;
}

#pragma mark - collection view data source

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _arrBlogDataUnsorted.count;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"BlogColCell" forIndexPath:indexPath];
    PostCollectionCell *postCell = (PostCollectionCell *)cell;
    
    //The following conditional was added due to the periodic error: NSArrayM objectAtIndex:]: index 2 beyond bounds for empty array
    if (_arrBlogDataUnsorted.count > indexPath.row) {
        Post *post = [_arrBlogDataUnsorted objectAtIndex:indexPath.row];
        postCell.titleLabel.text = post.title;
        postCell.dateLabel.text = [NSString stringWithFormat:@"%@ - %@", post.getDate, post.getTime];
        [postCell.backgroundImage setImageWithURL:[NSURL URLWithString:post.iPadThumbnail] placeholderImage:[UIImage imageNamed:@"WH_logo_3D_CMYK.png"]];

    } else {
        postCell.titleLabel.text = @"";
        postCell.dateLabel.text = @"";
    }
    
    cell.layer.shadowColor = [UIColor blackColor].CGColor;
    cell.layer.shadowRadius = 1;
    cell.layer.shadowOpacity = 0.2;
    cell.layer.shadowOffset = CGSizeMake(0.2, 2);
    cell.layer.masksToBounds = NO;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showActionSheet:)];
    [cell addGestureRecognizer:longPress];
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath  {
    //The following conditional was added due to the periodic error: __NSArrayM objectAtIndex:]: index 0 beyond bounds for empty array
    if (_arrBlogDataUnsorted.count > indexPath.row){
        Post *post = [_arrBlogDataUnsorted objectAtIndex:indexPath.row];
        NSURL *fileURL = [NSURL URLWithString:post.video];
        
        _moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:fileURL];
        _moviePlayerController.controlStyle = MPMovieControlStyleDefault;
        _moviePlayerController.shouldAutoplay = YES;
        [self.view addSubview:_moviePlayerController.view];
        [_moviePlayerController setFullscreen:YES animated:YES];
    }
}

#pragma mark UICollectionViewDelegate layout

-(CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    int totalGutterWidth = ([self cellsPerRow] + 1) * [self gutter];
    int cellSize = (self.view.frame.size.width - totalGutterWidth) / [self cellsPerRow];
    CGSize c = CGSizeMake(cellSize , cellSize);
    return c;
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                       layout:(UICollectionViewLayout*)collectionViewLayout
       insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake([self gutter],[self gutter],[self gutter],[self gutter]);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return [self gutter];
}

- (int)cellsPerRow{
    return 2;
}

- (int)gutter{
    return 25;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [_collectBlogsPlus performBatchUpdates:nil completion:nil];
    [_collectBlogs performBatchUpdates:nil completion:nil];
    [self createBanner];
    [self refreshData];
}

# pragma live event Banner
-(void)createBanner{
    [self.baseView removeFromSuperview];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.livePosts){
        NSMutableArray *happeningNow = [[NSMutableArray alloc]init];
        for (NSDictionary *d in appDelegate.livePosts) {
            Post *post = [Post postFromDictionary:d];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss ZZZ";
            NSDate *postDate = [formatter dateFromString: post.pubDate];
            NSDate *postDateEnd = [postDate dateByAddingTimeInterval:(+30*60)];
            NSDate *timeNow = [NSDate date];
            
            if([Post date:timeNow isBetweenDate:postDate andDate:postDateEnd]){
                [happeningNow addObject:post];
            }
        }
        if ([happeningNow count] > 0){
            NSString *msg = [[NSString alloc] init];
            UILabel *liveEventsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, self.view.frame.size.width, 20)];
            if ([happeningNow count] == 1){
                msg = [NSString stringWithFormat: @"Live: %@", [[happeningNow firstObject] title]];
                liveEventsLabel.text = [NSString stringWithFormat:@"%@", msg];
            }else {
                msg = @"live events. Watch Live";
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
            if (IS_IOS_8_OR_LATER){
                [_tblVideos setContentInset:UIEdgeInsetsMake(30,0,0,0)];
                [_collectBlogs setContentInset:UIEdgeInsetsMake(5,0,0,0)];
            }
            else{
                [_tblVideos setContentInset:UIEdgeInsetsMake(22,0,0,0)];
                [_collectBlogs setContentInset:UIEdgeInsetsMake(5,0,0,0)];
            }
            
            [_tblVideos scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
        }
    }
}

-(void)presentLiveViewController{
    [self.navigationController popToRootViewControllerAnimated:NO]; //Fixed crashing issue on iOS 8
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle: nil];
    
    LiveViewController *mainVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"LiveViewController"];
    UINavigationController *navVC =[[UINavigationController alloc]    initWithRootViewController:mainVC];
    [self.revealViewController setFrontViewController:navVC];
}

# pragma long press for favoriting videos

- (IBAction)showActionSheet:(UILongPressGestureRecognizer *)gestureRecognizer {
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        NSIndexPath *indexPath;
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            CGPoint p = [gestureRecognizer locationInView:_collectBlogs];
            indexPath = [_collectBlogs indexPathForItemAtPoint:p];
            _pressedPost = [self.arrBlogDataUnsorted objectAtIndex:indexPath.row];
        }else{
            CGPoint p = [gestureRecognizer locationInView:_tblVideos];
            indexPath = [_tblVideos indexPathForRowAtPoint:p];
            NSArray *set = [self.arrBlogData objectAtIndex:indexPath.section];
            _pressedPost = [set objectAtIndex:indexPath.row];
        }
        FavoritesViewController * favoriteController = [[FavoritesViewController alloc] init];
        if ([favoriteController isFavorited:_pressedPost]){
            _favoriteButtonTitle = @"Unfavorite";
        }else{
            _favoriteButtonTitle = @"Favorite";
        }
        UIAlertAction *favoriteAction = [UIAlertAction
                                         actionWithTitle:_favoriteButtonTitle
                                         style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction * action)
                                         {
                                             [self toggleFavorite:_pressedPost];
                                             
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
                                             [self shareFacebook:_pressedPost];
                                         }];
        UIAlertAction *twitterAction = [UIAlertAction
                                        actionWithTitle:@"Share on Twitter"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action)
                                        {
                                            [self shareTwitter:_pressedPost];
                                            
                                        }];
        UIAlertAction *emailAction = [UIAlertAction
                                      actionWithTitle:@"Share via e-mail"
                                      style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction * action)
                                      {
                                          [self shareEmail:_pressedPost];
                                          
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
            alertController.popoverPresentationController.barButtonItem = _sidebarButton;
        }else{
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:_favoriteButtonTitle, @"Share on Facebook", @"Share on Twitter", @"Share via e-mail", nil];
            
            [actionSheet showInView:self.view];
        }
    }

}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self toggleFavorite:_pressedPost];
            break;
        case 1:
            [self shareFacebook:_pressedPost];
            break;
        case 2:
            [self shareTwitter:_pressedPost];
            break;
        case 3:
            [self shareEmail:_pressedPost];
            break;
        default:
            break;
    }
}

- (void) shareFacebook:(Post*)post
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

- (void) shareTwitter:(Post*)post
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

-(void) shareEmail:(Post*)post
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

-(void) toggleFavorite:(Post*)post{
    FavoritesViewController * favoriteController = [[FavoritesViewController alloc] init];
    if ([favoriteController isFavorited:post]){
        [favoriteController removeFavoritesObject:post];
        _favoriteButtonTitle = @"Favorite";
    }else{
        [favoriteController addFavoritesObject:post];
        _favoriteButtonTitle = @"Unfavorite";
    }
}

-(CGFloat) tableView: (UITableView * ) tableView heightForRowAtIndexPath: (NSIndexPath * ) indexPath {
    
    NSArray *set = [_arrBlogData objectAtIndex:indexPath.section];
    Post *post = [set objectAtIndex:indexPath.row];
    NSString *title = [Post stringByStrippingHTML:post.title];
    
    //find the ratio of uppercase to totoal characters in string
    int numberUpperCase = 0;
    NSCharacterSet *upperCaseSet = [NSCharacterSet uppercaseLetterCharacterSet];
    for (int x=0; x<title.length; x++) {
        unichar aChar = [title characterAtIndex: x]; //get the first character from the string.
        if ([upperCaseSet characterIsMember: aChar])
            numberUpperCase++;
    }
    float a = numberUpperCase;
    float b = title.length;
    float upperToTotal = a/b;
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\?" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *string = [regex stringByReplacingMatchesInString:title options:0 range:NSMakeRange(0, [title length]) withTemplate:@""];
    
    CGSize size = [string sizeWithFont:[UIFont fontWithName:@"Helvetica" size:17] constrainedToSize:CGSizeMake(_tblVideos.frame.size.width, 999) lineBreakMode:NSLineBreakByWordWrapping];
    if (upperToTotal > 0.2) {
        return size.height + 270;
    }
    else
        return size.height + 255;


}

@end
