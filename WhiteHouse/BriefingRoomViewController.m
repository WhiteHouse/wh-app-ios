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
//  BriefingRoomViewController.m
//  WhiteHouse
//

#import "BriefingRoomViewController.h"
#import "AppDelegate.h"
#import "LiveViewController.h"
#import "Constants.h"

@interface BriefingRoomViewController ()
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSArray *arrBriefingData;
@property (nonatomic, assign) const float heightCon;
@property (nonatomic, strong) UIView *baseView;

-(void)refreshData;
-(void)performNewFetchedDataActionsWithDataArray:(NSArray *)dataArray;
@end

@implementation BriefingRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Briefing Room";
    
    // Set the side bar button action. When it's tapped, it'll show up the sidebar.
    _sidebarButton.target = self.revealViewController;
    _sidebarButton.action = @selector(revealToggle:);
    
    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    // fetching data
    [self.tblBlogs setDelegate:self];
    [self.tblBlogs setDataSource:self];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    
    [self.refreshControl addTarget:self
                            action:@selector(hardRefresh)
                  forControlEvents:UIControlEventValueChanged];
    
    [self.tblBlogs addSubview:self.refreshControl];
    
    self.tblBlogs.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    [[UITableViewHeaderFooterView appearance] setTintColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setTextColor:[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0]];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setFont:[UIFont fontWithName:@"Times" size:16]];
    self.view.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self createBanner];
    [self refreshData];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)hardRefresh{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.briefingRoomData removeAllObjects];
    [self refreshData];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self createBanner];
    [_tblBlogs reloadData];
}

-(void)refreshData{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    DOMParser * parser = [[DOMParser alloc] init];
    NSArray * posts;
    NSArray * sectionedPosts;
    if(appDelegate.briefingRoomData.count > 0){
        _arrBriefingData = appDelegate.briefingRoomData;
        sectionedPosts = [parser sectionPosts:appDelegate.briefingRoomData];
    }else{
        NSURL *url = [[NSURL alloc] initWithString:appDelegate.activeFeed];
        parser.xml = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        posts = [parser parseFeed];
        _arrBriefingData = posts;
        sectionedPosts = [parser sectionPosts:posts];
        appDelegate.briefingRoomData = [[NSMutableArray alloc] initWithArray:posts];
    }
    [self performNewFetchedDataActionsWithDataArray:sectionedPosts];
    [self.refreshControl endRefreshing];
}

-(void)performNewFetchedDataActionsWithDataArray:(NSArray *)dataArray{
    if (self.arrBriefingData != nil) {
        self.arrBriefingData = nil;
    }
    self.arrBriefingData = [[NSArray alloc] initWithArray:dataArray];
    [self.tblBlogs reloadData];
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return _arrBriefingData.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *posts = _arrBriefingData[section];
    Post *post = [posts firstObject];
    return [Post todayYesterdayOrDate:post.pubDate];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray *posts = _arrBriefingData[section];
    return posts.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    
    UITableViewCell *cell = nil;
    NSArray *set = [_arrBriefingData objectAtIndex:indexPath.section];
    Post *post = [set objectAtIndex:indexPath.row];
    cell = [tableView dequeueReusableCellWithIdentifier:@"BriefingCell" forIndexPath:indexPath];
    PostTableCell *blogCell = (PostTableCell *)cell;
    blogCell.titleLabel.text = post.title;
    blogCell.dateLabel.text = post.getTime;
    
    blogCell.card.layer.shadowColor = [UIColor blackColor].CGColor;
    blogCell.card.layer.shadowRadius = 1;
    blogCell.card.layer.shadowOpacity = 0.2;
    blogCell.card.layer.shadowOffset = CGSizeMake(0.2, 2);
    blogCell.card.layer.masksToBounds = NO;
    
    [cell setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //    NSDictionary *dict = [self.arrBlogData objectAtIndex:indexPath.row];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = [_tblBlogs indexPathForSelectedRow];
    NSArray *set = [_arrBriefingData objectAtIndex:indexPath.section];
    Post *post = [set objectAtIndex:indexPath.row];
    DetailViewController *destViewController = segue.destinationViewController;
    destViewController.post = post;
    if (_baseView.superview){//if live banner is loaded in view
        destViewController.liveBanner = true;
        [self.baseView removeFromSuperview];
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
            [_tblBlogs setContentInset:UIEdgeInsetsMake(30,0,0,0)];
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

-(CGFloat) tableView: (UITableView * ) tableView heightForRowAtIndexPath: (NSIndexPath * ) indexPath {
    if (IS_IOS_8_OR_LATER)
        return UITableViewAutomaticDimension;
    else {
        NSArray *set = [_arrBriefingData objectAtIndex:indexPath.section];
        Post *post = [set objectAtIndex:indexPath.row];
        NSError *error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\?" options:NSRegularExpressionCaseInsensitive error:&error];
        NSString *string = [regex stringByReplacingMatchesInString:post.title options:0 range:NSMakeRange(0, [post.title length]) withTemplate:@""];
        CGSize size = [string sizeWithFont:[UIFont fontWithName:@"Helvetica" size:17] constrainedToSize:CGSizeMake(_tblBlogs.frame.size.width, 999) lineBreakMode:NSLineBreakByWordWrapping];
        
        return size.height + 40;
    }
}

@end
