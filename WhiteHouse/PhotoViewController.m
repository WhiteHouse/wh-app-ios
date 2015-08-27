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
//  PhotoViewController.m
//  WhiteHouse
//

#import "PhotoViewController.h"
#import "DOMParser.h"
#import "Post.h"
#import "PostCollectionCell.h"
#import "UIKit+AFNetworking.h"
#import "ActivityViewCustomActivity.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"
#import "LiveViewController.h"
#import "Constants.h"

@interface PhotoViewController ()

@property (nonatomic, assign) const float heightCon;
@property (nonatomic, strong) UIView *baseView;

@end

@implementation PhotoViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    _sidebarButton.target = self.revealViewController;
    _sidebarButton.action = @selector(revealToggle:);
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    [self.collectPhotos setDelegate:self];
    [self.collectPhotos setDataSource:self];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    _screenWidth = screenRect.size.width;
    _screenHeight = screenRect.size.height;
    [self refreshData];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self createBanner];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated{
    if (_baseView.superview)
        _baseView.hidden = FALSE;
}

-(void)refreshData{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    DOMParser * parser = [[DOMParser alloc] init];
    NSArray * posts;
    if(appDelegate.photoData.count > 0){
        _photos = appDelegate.photoData;
    }else{
        NSURL *url = [[NSURL alloc] initWithString:appDelegate.activeFeed];
        parser.xml = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        posts = [parser parseFeed];
        _photos = posts;
        appDelegate.photoData = [[NSMutableArray alloc] initWithArray:posts];
    }
    _mwPhotos = [[NSMutableArray alloc] init];
    NSString *image;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
        ([UIScreen mainScreen].scale == 2.0)) {
        image = @"mobile2048";
    } else {
        image = @"mobile1024";
    }
    for (Post *post in _photos) {
        MWPhoto *photo = [MWPhoto photoWithURL:[NSURL URLWithString:[post valueForKey: image]]];
        NSString *rawCaption = [self stringByStrippingHTML:post.pageDescription];
        NSRange range = [rawCaption rangeOfString:@"^\\s*" options:NSRegularExpressionSearch];
        NSString *result = [rawCaption stringByReplacingCharactersInRange:range withString:@""];
        photo.caption = result;
        [_mwPhotos addObject:photo];
    }
    [self performNewFetchedDataActionsWithDataArray:_photos];
}

-(void)performNewFetchedDataActionsWithDataArray:(NSArray *)dataArray{
    if (self.photos != nil) {
        self.photos = nil;
    }
    self.photos = [[NSArray alloc] initWithArray:dataArray];
    [self.collectPhotos reloadData];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    Post *post = [_photos objectAtIndex:indexPath.row];
    NSString *image;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
        ([UIScreen mainScreen].scale == 2.0)) {
        image = post.iPadThumbnail;
    } else {
        image = post.collectionThumbnail;
    }
    UICollectionViewCell *cell = nil;
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    PostCollectionCell *postCell = (PostCollectionCell *)cell;
    [postCell.backgroundImage setImageWithURL:[NSURL URLWithString:post.collectionThumbnail] placeholderImage:[UIImage imageNamed:@"WH_logo_3D_CMYK.png"]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    _baseView.hidden = YES;
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = YES; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.enableGrid = NO; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    [browser setCurrentPhotoIndex:indexPath.row];
    [self.navigationController pushViewController:browser animated:YES];
    
    NSString *photoUrl = [[_photos objectAtIndex:indexPath.row] link];
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"photoLoaded"     // Event category (required)
                                                          action:@"button_press"  // Event action (required)
                                                           label: photoUrl         // Event label
                                                           value:nil] build]];    // Event value
}

#pragma mark <UICollectionViewDelegate>

-(CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    int totalGutterWidth = ([self cellsPerRow] + 1) * [self gutter];
    int cellSize = (self.view.frame.size.width - totalGutterWidth) / [self cellsPerRow];
    CGSize c = CGSizeMake(cellSize , cellSize * .8);
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
    return 5;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.collectionView performBatchUpdates:nil completion:nil];
    [self createBanner];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _mwPhotos.count)
        return [_mwPhotos objectAtIndex:index];
    return nil;
}
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (index < _mwPhotos.count)
        return [_mwPhotos objectAtIndex:index];
    return nil;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
    
    NSArray *items = [NSArray arrayWithObjects: UIActivityTypePostToFacebook, UIActivityTypePostToTwitter, UIActivityTypeMail, nil];
    
    ActivityViewCustomActivity *ca = [[ActivityViewCustomActivity alloc]init];
    FavoritesViewController * favoriteController = [[FavoritesViewController alloc] init];
    Post *post = [_photos objectAtIndex:index];
    NSString *activityName;
    if ([favoriteController isFavorited:post]){
        activityName = @"Unfavorite";
    }else{
        activityName = @"Favorite";
    }
    ca.activityTitle = activityName;
    ca.post = post;
    UIActivityViewController *activityVC =
    [[UIActivityViewController alloc] initWithActivityItems:items
                                      applicationActivities:[NSArray arrayWithObject:ca]];
    
    activityVC.excludedActivityTypes = @[UIActivityTypePostToWeibo];
    
    [photoBrowser presentViewController:activityVC animated:YES completion:nil];
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad  && [UIPopoverPresentationController class]){
        activityVC.popoverPresentationController.sourceView = self.view;
    }

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
            [_collectPhotos setContentInset:UIEdgeInsetsMake(30,0,0,0)];
            
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

-(NSString *) stringByStrippingHTML: (NSString*) s {
    NSRange r;
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return s;
}

@end
