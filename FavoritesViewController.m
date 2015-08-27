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
//  FavoritesViewController.m
//  WhiteHouse
//

#import "FavoritesViewController.h"
#import "DetailViewController.h"
#import "Post.h"
#import "PostTableCell.h"
#import "PostCollectionCell.h"
#import "UIKit+AFNetworking.h"
#import "ActivityViewCustomActivity.h"
#import "GAI.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "AppDelegate.h"
#import "LiveViewController.h"
#import "Social/Social.h"
#import "Constants.h"

@interface FavoritesViewController ()
@property (nonatomic, strong) NSString *favoritesFilePath;
@property (nonatomic, strong) NSIndexPath *colIndex;
@property (nonatomic, assign) const float heightCon;
@property (nonatomic, strong) UIView *baseView;
@property (weak, nonatomic) NSString *favoriteButtonTitle;
@property (weak, nonatomic) UIAlertView *alert;
@end

@implementation FavoritesViewController

Post *post;
BOOL alertShowing = NO;

- (void)viewDidLoad {
    [super viewDidLoad];
    
     _noFavoritesView.layer.zPosition = MAXFLOAT;

    _sidebarButton.target = self.revealViewController;
    _sidebarButton.action = @selector(revealToggle:);
    
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    [self.tblFavorites setDelegate:self];
    [self.tblFavorites setDataSource:self];
    [self.collectBlogs setDelegate:self];
    [self.collectBlogs setDataSource:self];
    [self.collectBlogsPlus setDelegate:self];
    [self.collectBlogsPlus setDataSource:self];
    
    //self.tblFavorites.estimatedRowHeight = 255.0;
    //self.tblFavorites.rowHeight = UITableViewAutomaticDimension;
    
    [_tblFavorites setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
    [_collectBlogsPlus setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
    [_collectBlogs setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
    self.view.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self createBanner];
    _noFavoritesView.hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:true];
     _placeholderImageIndex = 0;
    [self refreshData];
}

- (void) refreshData
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    self.favoritesFilePath = [docDirectory stringByAppendingPathComponent:@"favoritesdata"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.favoritesFilePath]) {
        NSArray *dictsFromFile = [[NSMutableArray alloc] initWithContentsOfFile:self.favoritesFilePath];
        NSMutableArray *obList = [[NSMutableArray alloc]init];
        for (NSDictionary *dict in dictsFromFile) {
            [obList addObject:[Post postFromDictionary:dict]];
        }
        _favorites = [NSMutableArray arrayWithArray:obList];
        [self.tblFavorites reloadData];
        _photos = [[NSMutableArray alloc]init];
        for (Post *post in _favorites) {
            MWPhoto *photo = [MWPhoto photoWithURL:[NSURL URLWithString:post.mobile2048]];
            photo.caption = post.title;
            [_photos addObject:photo];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.tblFavorites reloadData];
    [self.collectBlogs reloadData];
    
    if (_favorites.count < 1){
        _noFavoritesView.hidden = NO;
    }else{
        _noFavoritesView.hidden = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)addFavoritesObject:(Post *)post{
    NSDictionary *page = [[NSDictionary alloc]initWithDictionary:[Post dictionaryFromPost:post]];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    self.favoritesFilePath = [docDirectory stringByAppendingPathComponent:@"favoritesdata"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.favoritesFilePath]) {
        self.favorites = [[NSMutableArray alloc] initWithContentsOfFile:self.favoritesFilePath];
        [self.favorites addObject:page];
        if (![self.favorites writeToFile:self.favoritesFilePath atomically:YES]) {
            NSLog(@"Couldn't save favorite");
        }
    }else{
        self.favorites = [[NSMutableArray alloc] init];
        [self.favorites addObject:page];
        if (![self.favorites writeToFile:self.favoritesFilePath atomically:YES]) {
            NSLog(@"Couldn't save favorite");
        }
    }
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"addedFavorite"     // Event category (required)
                                                          action:@"button_press"  // Event action (required)
                                                           label: post.link         // Event label
                                                           value:nil] build]];    // Event value
}

-(void)removeFavoritesObject:(Post *)post{
    NSDictionary *page = [[NSDictionary alloc]initWithDictionary:[Post dictionaryFromPost:post]];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    self.favoritesFilePath = [docDirectory stringByAppendingPathComponent:@"favoritesdata"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.favoritesFilePath]) {
        self.favorites = [[NSMutableArray alloc] initWithContentsOfFile:self.favoritesFilePath];
        NSInteger theIndex = [self indexOfFavorite:page in:self.favorites];
        if (theIndex != -1){
            [self.favorites removeObjectAtIndex: theIndex];
            if (![self.favorites writeToFile:self.favoritesFilePath atomically:YES]) {
                NSLog(@"Couldn't save favorite");
            }else{
                NSLog(@"%ul", (unsigned int)_favorites.count);
            }
            if (self.favorites.count == 0){
                _noFavoritesView.hidden = false;
            }
        }
    }
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"removedFavorite"     // Event category (required)
                                                          action:@"button_press"  // Event action (required)
                                                           label: post.link         // Event label
                                                           value:nil] build]];    // Event value
}

-(NSInteger) indexOfFavorite:(NSDictionary*)fav in:(NSArray*) favs{
    NSInteger index = -1;
    for (int i=0; i<favs.count; i+=1) {
        if ([[[favs objectAtIndex:i] objectForKey:@"url"]isEqualToString:[fav objectForKey:@"url"]]){
            index = i;
            break;
        }else{
            index= -1;
        }
    }
    return index;
}

-(BOOL)isFavorited:(Post*)post{
    NSDictionary *page = [[NSDictionary alloc]initWithDictionary:[Post dictionaryFromPost:post]];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    _favoritesFilePath = [docDirectory stringByAppendingPathComponent:@"favoritesdata"];
    BOOL found = false;
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.favoritesFilePath]) {
        NSArray *currentFavorites = [[NSMutableArray alloc] initWithContentsOfFile:self.favoritesFilePath];
        if ([self indexOfFavorite:page in:currentFavorites] != -1){
            found = true;
        }
    }
    return found;
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.favorites.count;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UITableViewCell *cell = nil;
    Post *post = [_favorites objectAtIndex:indexPath.row];
    PostTableCell *blogCell;
    if(post.video){
        cell = [tableView dequeueReusableCellWithIdentifier:@"VideoCell" forIndexPath:indexPath];
        PostCollectionCell *blogCell = (PostCollectionCell *)cell;
        [blogCell.backgroundImage setImageWithURL:[NSURL URLWithString:post.iPadThumbnail] placeholderImage:[UIImage imageNamed:@"WH_logo_3D_CMYK.png"]];
        blogCell.titleLabel.text = post.title;
        blogCell.dateLabel.text = [NSString stringWithFormat:@"%@ - %@", post.getDate, post.getTime];
    }else if (post.iPadThumbnail){
        cell = [tableView dequeueReusableCellWithIdentifier:@"BlogCell" forIndexPath:indexPath];
        blogCell = (PostTableCell *)cell;
        [blogCell.backgroundImage setImageWithURL:[NSURL URLWithString:post.iPadThumbnail] placeholderImage: appDelegate.placeholderImages[_placeholderImageIndex]];
        (_placeholderImageIndex == 3) ? _placeholderImageIndex = 0 : _placeholderImageIndex++;
        blogCell.titleLabel.text = post.title;
        blogCell.dateLabel.text = [NSString stringWithFormat:@"%@ - %@", post.getDate, post.getTime];
    }else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"BlogCellNoImage" forIndexPath:indexPath];
        blogCell = (PostTableCell *)cell;
        blogCell.titleLabel.text = post.title;
        blogCell.dateLabel.text = [NSString stringWithFormat:@"%@ - %@", post.getDate, post.getTime];
    }
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showActionSheet:)];
    [cell addGestureRecognizer:longPress];
    
    blogCell.card.layer.shadowColor = [UIColor blackColor].CGColor;
    blogCell.card.layer.shadowRadius = 1;
    blogCell.card.layer.shadowOpacity = 0.2;
    blogCell.card.layer.shadowOffset = CGSizeMake(0.2, 2);
    blogCell.card.layer.masksToBounds = NO;
    
    [cell setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    Post *post = [_favorites objectAtIndex:indexPath.row];
    if ([post.type isEqualToString:@"photo"]){
        MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
        
        // Set options
        browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
        browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
        browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
        browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
        browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
        browser.enableGrid = NO; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
        browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
        [browser setCurrentPhotoIndex:indexPath.row];
        [self.navigationController pushViewController:browser animated:YES];
    }else{
        if(post.video){
            NSURL *fileURL = [NSURL URLWithString:post.video];
            
            _moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:fileURL];
            _moviePlayerController.controlStyle = MPMovieControlStyleDefault;
            _moviePlayerController.shouldAutoplay = YES;
            [self.view addSubview:_moviePlayerController.view];
            [_moviePlayerController setFullscreen:YES animated:YES];
        }else{
            [self performSegueWithIdentifier:@"FavToDetailSegue" sender:self];
        }
    }

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    Post *post;
    if (_tblFavorites.superview == self.view){
        NSIndexPath *indexPath = [_tblFavorites indexPathForSelectedRow];
        post = [_favorites objectAtIndex:indexPath.row];
    }else{
        post = [_favorites objectAtIndex:_colIndex.row];
    }
    DetailViewController *destViewController = segue.destinationViewController;
    destViewController.post = post;
}

#pragma mark - collection view data source

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (IS_IPAD || IS_IPHONE_6P)
        return _favorites.count;
    else
        return 0;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    if (IS_IPAD || IS_IPHONE_6P)
        return 1;
    else
        return 0;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UICollectionViewCell *cell = nil;
    Post *post = [_favorites objectAtIndex:indexPath.row];
    if(post.video){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoColCell" forIndexPath:indexPath];
        PostCollectionCell *blogCell = (PostCollectionCell *)cell;
        [blogCell.backgroundImage setImageWithURL:[NSURL URLWithString:post.iPadThumbnail] placeholderImage:[UIImage imageNamed:@"WH_logo_3D_CMYK.png"]];
        blogCell.titleLabel.text = post.title;
        blogCell.dateLabel.text = [NSString stringWithFormat:@"%@ - %@", post.getDate, post.getTime];
    }else if (post.iPadThumbnail){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"BlogColCell" forIndexPath:indexPath];
        PostCollectionCell *blogCell = (PostCollectionCell *)cell;
        [blogCell.backgroundImage setImageWithURL:[NSURL URLWithString:post.iPadThumbnail] placeholderImage:appDelegate.placeholderImages[_placeholderImageIndex]];
        (_placeholderImageIndex == 3) ? _placeholderImageIndex = 0 : _placeholderImageIndex++;
        blogCell.titleLabel.text = post.title;
        blogCell.dateLabel.text = [NSString stringWithFormat:@"%@ - %@", post.getDate, post.getTime];
    }else{
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"BlogColCellNoImage" forIndexPath:indexPath];
        PostCollectionCell *blogCell = (PostCollectionCell *)cell;
        blogCell.titleLabel.text = post.title;
        blogCell.dateLabel.text = [NSString stringWithFormat:@"%@ - %@", post.getDate, post.getTime];
        blogCell.descriptionLabel.text = [Post stringByStrippingHTML:post.pageDescription];
    }
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showActionSheet:)];
    [cell addGestureRecognizer:longPress];
    
    cell.layer.shadowColor = [UIColor blackColor].CGColor;
    cell.layer.shadowRadius = 1;
    cell.layer.shadowOpacity = 0.2;
    cell.layer.shadowOffset = CGSizeMake(0.2, 2);
    cell.layer.masksToBounds = NO;
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath  {
    _colIndex = indexPath;
    Post *post = [_favorites objectAtIndex:indexPath.row];
    if ([post.type isEqualToString:@"photo"]){
        MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
        
        // Set options
        browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
        browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
        browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
        browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
        browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
        browser.enableGrid = NO; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
        browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
        [browser setCurrentPhotoIndex:indexPath.row];
        [self.navigationController pushViewController:browser animated:YES];
    }else{
        if(post.video){
            NSURL *fileURL = [NSURL URLWithString:post.video];
            
            _moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:fileURL];
            _moviePlayerController.controlStyle = MPMovieControlStyleDefault;
            _moviePlayerController.shouldAutoplay = YES;
            [self.view addSubview:_moviePlayerController.view];
            [_moviePlayerController setFullscreen:YES animated:YES];
        }else{
            [self performSegueWithIdentifier:@"FavToDetailSegue" sender:self];
        }
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

- (UICollectionViewFlowLayout *)flowLayout {
    return (UICollectionViewFlowLayout *)self.collectBlogsPlus.collectionViewLayout;
}

#define NUMBER_OF_CELLS_PER_ROW 2
- (CGSize)itemSizeInCurrentOrientation {
    CGFloat windowWidth = self.collectBlogsPlus.window.bounds.size.width;
    
    CGFloat width = (windowWidth - (self.flowLayout.minimumInteritemSpacing * (NUMBER_OF_CELLS_PER_ROW - 1)) - self.flowLayout.sectionInset.left - self.flowLayout.sectionInset.right)/NUMBER_OF_CELLS_PER_ROW;
    
    CGFloat height = 80.0f;
    
    return CGSizeMake(width, height);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (IS_IPAD || IS_IPHONE_6P){
        [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
        [self.flowLayout invalidateLayout];
        self.flowLayout.itemSize = [self itemSizeInCurrentOrientation];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    if (IS_IPAD || IS_IPHONE_6P){
        [_collectBlogsPlus performBatchUpdates:nil completion:nil];
        [_collectBlogs performBatchUpdates:nil completion:nil];
        [_collectBlogsPlus reloadData];
    } else
        [_tblFavorites reloadData];
    [self createBanner];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _favorites.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
    
    NSArray *items = [NSArray arrayWithObjects: UIActivityTypePostToFacebook, UIActivityTypePostToTwitter, UIActivityTypeMail, nil];
    
    ActivityViewCustomActivity *ca = [[ActivityViewCustomActivity alloc]init];
    Post *post = [_favorites objectAtIndex:index];
    NSString *activityName;
    if ([self isFavorited:post]){
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
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ){
        activityVC.popoverPresentationController.sourceView = self.view;
    }
}

# pragma live event Banner
-(void)createBanner{
    [self.baseView removeFromSuperview];
    NSLog(@"%F", _heightCon);
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
                [_tblFavorites setContentInset:UIEdgeInsetsMake(30,0,0,0)];
                [_collectBlogs setContentInset:UIEdgeInsetsMake(5,0,0,0)];
            }
            else{
                [_tblFavorites setContentInset:UIEdgeInsetsMake(22,0,0,0)];
                [_collectBlogs setContentInset:UIEdgeInsetsMake(5,0,0,0)];
            }
        }
    }
}

-(void)presentLiveViewController{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle: nil];
    
    LiveViewController *mainVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"LiveViewController"];
    UINavigationController *navVC =[[UINavigationController alloc]    initWithRootViewController:mainVC];
    [self.revealViewController setFrontViewController:navVC];
}

# pragma long press for favoriting videos

- (IBAction)showActionSheet:(UILongPressGestureRecognizer *)gestureRecognizer {
    NSIndexPath *indexPath;
    //Post *post;
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        CGPoint p = [gestureRecognizer locationInView:_collectBlogs];
        indexPath = [_collectBlogs indexPathForItemAtPoint:p];
        post = [_favorites objectAtIndex:indexPath.row];
    }else{
        CGPoint p = [gestureRecognizer locationInView:_tblFavorites];
        indexPath = [_tblFavorites indexPathForRowAtPoint:p];
        post = [_favorites objectAtIndex:indexPath.row];
    }
    FavoritesViewController * favoriteController = [[FavoritesViewController alloc] init];
    if ([favoriteController isFavorited:post]){
        _favoriteButtonTitle = @"Unfavorite";
    }else{
        _favoriteButtonTitle = @"Favorite";
    }
    
    if (IS_IOS_8_OR_LATER) {
    
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Actions"
                                              message:@"Share or save this page"
                                              preferredStyle:UIAlertControllerStyleActionSheet];
        [self presentViewController:alertController animated:YES completion:nil];
        UIAlertAction *favoriteAction = [UIAlertAction
                                         actionWithTitle:_favoriteButtonTitle
                                         style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction * action)
                                         {
                                             [self toggleFavorite:post];
                                             
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
                                             
                                         }];
        UIAlertAction *twitterAction = [UIAlertAction
                                        actionWithTitle:@"Share on Twitter"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action)
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
                                            
                                        }];
        UIAlertAction *emailAction = [UIAlertAction
                                      actionWithTitle:@"Share via e-mail"
                                      style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction * action)
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
                                          
                                      }];
        
        [alertController addAction:favoriteAction];
        [alertController addAction:facebookAction];
        [alertController addAction:twitterAction];
        [alertController addAction:emailAction];
        [alertController addAction:cancelAction];
        
        alertController.popoverPresentationController.barButtonItem = _sidebarButton;
    }
    
    else {
        if (!alertShowing) {
            UIAlertView *alertView =[[UIAlertView alloc ] initWithTitle:@"Actions"
                                                                message:@"Share or save this page"
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles: nil];
            [alertView addButtonWithTitle:_favoriteButtonTitle];
            [alertView addButtonWithTitle:@"Share on Facebook"];
            [alertView addButtonWithTitle:@"Share on Twitter"];
            [alertView addButtonWithTitle:@"Share via Email"];
            alertShowing = YES;
            [alertView show];
        }
    }
}

- (void)alertView: (UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertShowing = NO;
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:_favoriteButtonTitle]){
        [self toggleFavorite:post];
        
    }else if([title isEqualToString:@"Share on Facebook"]) {
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
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

    } else if ([title isEqualToString:@"Share on Twitter"]) {
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

    } else if ( [title isEqualToString:@"Share via Email"]){
        NSString *emailTitle = @"Sent from the White House iOS App";
        NSString *messageBody = post.link;
        //NSArray *toRecipents = [NSArray arrayWithObject:@"ryan@example.com"];
        
        MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
        mc.mailComposeDelegate = self;
        [mc setSubject:emailTitle];
        [mc setMessageBody:messageBody isHTML:NO];
        //                                        [mc setToRecipients:toRecipents];
        
        // Present mail view controller on screen
        [self presentViewController:mc animated:YES completion:NULL];
    } else if ( [title isEqualToString:@"Cancel"]){
        [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
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

-(void) toggleFavorite:(Post*)post{
    if ([self isFavorited:post]){
        [self removeFavoritesObject:post];
        _favoriteButtonTitle = @"Favorite";
    }else{
        [self addFavoritesObject:post];
        _favoriteButtonTitle = @"Unfavorite";
    }
    [self refreshData];
    [_tblFavorites reloadData];
    [_collectBlogs reloadData];
    [_collectBlogsPlus reloadData];
    
}


-(CGFloat) tableView: (UITableView * ) tableView heightForRowAtIndexPath: (NSIndexPath * ) indexPath {
    Post *post = [_favorites objectAtIndex:indexPath.row];
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
    CGSize size = [string sizeWithFont:[UIFont fontWithName:@"Helvetica" size:17] constrainedToSize:CGSizeMake(_tblFavorites.frame.size.width, 999) lineBreakMode:NSLineBreakByWordWrapping];
    if (post.iPadThumbnail || post.video){
        if (upperToTotal > 0.2)
            return size.height + 270;
        else
            return size.height + 255;
    }
    else{
        return size.height + 40;
    }
}

@end
