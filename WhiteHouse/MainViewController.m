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
//  MainViewController.m
//  WhiteHouse
//

#import "MainViewController.h"
#import "SWRevealViewController.h"
#import "DOMParser.h"
#import "UIKit+AFNetworking.h"
#import "PostCollectionCell.h"
#import "PostTableCell.h"
#import "Post.h"
#import "AppDelegate.h"
#import "WebViewController.h"
#import "LiveViewController.h"
#import "Constants.h"

@interface MainViewController ()
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSArray *arrBlogData;
@property (nonatomic, strong) NSArray *arrBlogDataUnsorted;
@property (nonatomic, strong) NSIndexPath *colIndex;
@property (nonatomic, assign) const float heightCon;
@property (nonatomic, strong) UIView *baseView;


-(void)refreshData;


@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIColor *blue = [UIColor colorWithRed:0.0 green:0.2 blue:0.4 alpha:1.0];
    [[UINavigationBar appearance] setBarTintColor:blue];
    
    self.title = @"Blog";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // Set the side bar button action. When it's tapped, it'll show up the sidebar.
    _sidebarButton.target = self.revealViewController;
    _sidebarButton.action = @selector(revealToggle:);
    
    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    // fetching data
    [self.tblBlogs setDelegate:self];
    [self.tblBlogs setDataSource:self];
    [self.collectBlogs setDelegate:self];
    [self.collectBlogs setDataSource:self];
    [self.collectBlogsPlus setDelegate:self];
    [self.collectBlogsPlus setDataSource:self];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    
    [self.refreshControl addTarget:self
                            action:@selector(hardRefresh)
                  forControlEvents:UIControlEventValueChanged];
    
    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType isEqualToString:@"iPad"]){
        [self.collectBlogs addSubview:self.refreshControl];
    }else{
        [self.tblBlogs addSubview:self.refreshControl];
    }
    self.view.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    self.tblBlogs.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    [[UITableViewHeaderFooterView appearance] setTintColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setTextColor:[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0]];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setFont:[UIFont fontWithName:@"Times" size:16]];
    [_collectBlogsPlus setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
    [_collectBlogs setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    _placeholderImageIndex = 0;
}

-(IBAction)viewEvent{
    if(_liveLink){
        [self performSegueWithIdentifier:@"showWebView" sender:self];
    }
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self createBanner];
    [self refreshData];
}
- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [_tblBlogs reloadData];
    [_collectBlogs reloadData];
    _placeholderImageIndex = 0;
}

- (void)appDidBecomeActive:(NSNotification *)notification {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _liveLink = appDelegate.liveLink;
    if(_liveLink){
        [self performSegueWithIdentifier:@"showWebView" sender:self];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


-(void)hardRefresh{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.blogData removeAllObjects];
    [self refreshData];
}

-(void)refreshData{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    DOMParser * parser = [[DOMParser alloc] init];
    NSArray * posts;
    NSArray * sectionedPosts;
    if(appDelegate.blogData.count > 0){
        _arrBlogDataUnsorted = appDelegate.blogData;
        sectionedPosts = [parser sectionPosts:appDelegate.blogData];
    }else{
    NSLog(@"%@", appDelegate.activeFeed);
        NSURL *url = [[NSURL alloc] initWithString:appDelegate.activeFeed];
        parser.xml = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        posts = [parser parseFeed];
        _arrBlogDataUnsorted = posts;
        sectionedPosts = [parser sectionPosts:posts];
        appDelegate.blogData = [[NSMutableArray alloc] initWithArray:posts];
    }
    [self performNewFetchedDataActionsWithDataArray:sectionedPosts];
    [self.refreshControl endRefreshing];
}

-(void)performNewFetchedDataActionsWithDataArray:(NSArray *)dataArray{
    if (_arrBlogData != nil) {
        _arrBlogData = nil;
    }
    _arrBlogData = [[NSArray alloc] initWithArray:dataArray];
    [_tblBlogs reloadData];
    [_collectBlogs reloadData];
    [_collectBlogsPlus reloadData];
    _placeholderImageIndex = 0;
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
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UITableViewCell *cell = nil;
    NSArray *set = [_arrBlogData objectAtIndex:indexPath.section];
    Post *post = [set objectAtIndex:indexPath.row];
    PostTableCell *blogCell;
    if ([NSURL URLWithString:post.iPhoneThumbnail]){
        cell = [tableView dequeueReusableCellWithIdentifier:@"BlogCell" forIndexPath:indexPath];
        blogCell = (PostTableCell *)cell;
        [blogCell.backgroundImage setImageWithURL:[NSURL URLWithString:post.iPadThumbnail] placeholderImage: appDelegate.placeholderImages[_placeholderImageIndex]];
        (_placeholderImageIndex == 3) ? _placeholderImageIndex = 0 : _placeholderImageIndex++;
    }else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"BlogCellNoImage" forIndexPath:indexPath];
        blogCell = (PostTableCell *)cell;
    }
    blogCell.titleLabel.text = post.title;
    blogCell.dateLabel.text = post.getTime;
    blogCell.card.layer.shadowColor = [UIColor blackColor].CGColor;
    blogCell.card.layer.shadowRadius = 1;
    blogCell.card.layer.shadowOpacity = 0.2;
    blogCell.card.layer.shadowOffset = CGSizeMake(0.2, 2);
    blogCell.card.layer.masksToBounds = NO;
    
    [cell setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self performSegueWithIdentifier:@"presentDetail" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"showWebView"]){
        WebViewController *w = segue.destinationViewController;
        w.url = _liveLink;
    }else{
        Post *post;
        if (_tblBlogs.superview == self.view){
            NSIndexPath *indexPath = [_tblBlogs indexPathForSelectedRow];
            NSArray *set = [self.arrBlogData objectAtIndex:indexPath.section];
            post = [set objectAtIndex:indexPath.row];
        }else{
            post = [_arrBlogDataUnsorted objectAtIndex:_colIndex.row];
        }
        DetailViewController *destViewController = segue.destinationViewController;
        destViewController.post = post;
        if (_baseView.superview){//if live banner is loaded in view
            destViewController.liveBanner = true;
            [self.baseView removeFromSuperview];
        }
    }
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
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UICollectionViewCell *cell = nil;
    PostCollectionCell *postCell;
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"BlogColCell" forIndexPath:indexPath];
    postCell = (PostCollectionCell *)cell;
    
    //The following conditional was added due to the periodic error: NSArrayM objectAtIndex:]: index 0 beyond bounds for empty array
    if (_arrBlogDataUnsorted.count > indexPath.row) {
        Post *post = [_arrBlogDataUnsorted objectAtIndex:indexPath.row];
        postCell.titleLabel.text = post.title;
        postCell.dateLabel.text = [NSString stringWithFormat:@"%@ - %@", post.getDate, post.getTime];
        [postCell.backgroundImage setImageWithURL:[NSURL URLWithString:post.iPadThumbnail] placeholderImage: appDelegate.placeholderImages[_placeholderImageIndex]];
        (_placeholderImageIndex == 3) ? _placeholderImageIndex = 0 : _placeholderImageIndex++;
    }
    else {
        postCell.titleLabel.text = @"No Blog data found";
        postCell.dateLabel.text = @"";
    }


    cell.layer.shadowColor = [UIColor blackColor].CGColor;
    cell.layer.shadowRadius = 1;
    cell.layer.shadowOpacity = 0.2;
    cell.layer.shadowOffset = CGSizeMake(0.2, 2);
    cell.layer.masksToBounds = NO;
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath  {
    _colIndex = indexPath;
    [self performSegueWithIdentifier:@"presentDetail" sender:self];
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

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [_tblBlogs reloadData];
    [_collectBlogs reloadData];
    [_collectBlogsPlus reloadData];
    _placeholderImageIndex = 0;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [_collectBlogsPlus performBatchUpdates:nil completion:nil];
    [_collectBlogs performBatchUpdates:nil completion:nil];
    [self createBanner];
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
                if (IS_IPHONE_6P)
                    self.heightCon = (self.view.bounds.size.height > self.view.bounds.size.width)? 64 : 44;
                else
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
                [_tblBlogs setContentInset:UIEdgeInsetsMake(30,0,0,0)];
                if(IS_IPHONE_6P)
                    [_collectBlogs setContentInset:UIEdgeInsetsMake(10,0,0,0)];
                else
                    [_collectBlogs setContentInset:UIEdgeInsetsMake(5,0,0,0)];
            }
            else{
                [_tblBlogs setContentInset:UIEdgeInsetsMake(30,0,0,0)];
                [_collectBlogs setContentInset:UIEdgeInsetsMake(5,0,0,0)];
            }
        }
    }
}

-(void)presentLiveViewController{
    [self.navigationController popToRootViewControllerAnimated:NO]; 
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle: nil];
    
    LiveViewController *mainVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"LiveViewController"];
    UINavigationController *navVC =[[UINavigationController alloc]    initWithRootViewController:mainVC];
    [self.revealViewController setFrontViewController:navVC];
    
}

-(CGFloat) tableView: (UITableView * ) tableView heightForRowAtIndexPath: (NSIndexPath * ) indexPath {
    NSArray *set = [_arrBlogData objectAtIndex:indexPath.section];
    Post *post = [set objectAtIndex:indexPath.row];
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\?" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *string = [regex stringByReplacingMatchesInString:post.title options:0 range:NSMakeRange(0, [post.title length]) withTemplate:@""];
    CGSize size = [string sizeWithFont:[UIFont fontWithName:@"Helvetica" size:17] constrainedToSize:CGSizeMake(_tblBlogs.frame.size.width, 999) lineBreakMode:NSLineBreakByWordWrapping];
    if (post.iPadThumbnail)
        return size.height + 255;
    else
        return size.height + 40;
}
@end
