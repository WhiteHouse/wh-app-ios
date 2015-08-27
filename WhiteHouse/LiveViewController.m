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
//  LiveViewController.m
//  WhiteHouse
//

#import "LiveViewController.h"
#import "DOMParser.h"
#import "WebViewController.h"
#import "Post.h"
#import "AppDelegate.h"
#import "PostTableCell.h"

@interface LiveViewController ()

@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSArray *arrNewsData;
@property (nonatomic, strong) NSArray *arrNewsDataSorted;
@property (nonatomic, strong) NSString *dataFilePath;
@property (nonatomic, strong) NSIndexPath *colIndex;

-(void)refreshData;
-(void)performNewFetchedDataActionsWithDataArray:(NSArray *)dataArray;

@end

@implementation LiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _sidebarButton.target = self.revealViewController;
    _sidebarButton.action = @selector(revealToggle:);
    
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    [_tblNews setDelegate:self];
    [_tblNews setDataSource:self];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    _dataFilePath = [docDirectory stringByAppendingPathComponent:@"livedata"];
    
    _refreshControl = [[UIRefreshControl alloc] init];
    
    [_refreshControl addTarget:self
                            action:@selector(refreshData)
                  forControlEvents:UIControlEventValueChanged];
    
    [_tblNews addSubview:self.refreshControl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:_dataFilePath]) {
        NSArray *dictsFromFile = [[NSMutableArray alloc] initWithContentsOfFile:_dataFilePath];
        NSMutableArray *obList = [[NSMutableArray alloc]init];
        for (NSDictionary *dict in dictsFromFile) {
            [obList addObject:[Post postFromDictionary:dict]];
        }
        _arrNewsData = [NSArray arrayWithArray:obList];
        DOMParser *parser = [[DOMParser alloc]init];
        _arrNewsDataSorted = [NSArray arrayWithArray:[parser sectionPostsByToday:obList]];
        [_tblNews reloadData];
    }
//    [self refreshData];    <=== this being commented forces app to rely on background refresh
    
    _noLiveEventsView.hidden = YES;
    
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"seal-bg.png"]];
    tempImageView.contentMode = UIViewContentModeScaleAspectFill;
    [tempImageView setFrame:_tblNews.frame];
    
    _tblNews.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    _tblNews.backgroundView = tempImageView;
    
    [[UITableViewHeaderFooterView appearance] setTintColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
    self.view.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];

    self.edgesForExtendedLayout = UIRectEdgeNone;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated {
    [self.tblNews reloadData];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    if ([[_arrNewsDataSorted objectAtIndex:0] count] < 1 && [[_arrNewsDataSorted objectAtIndex:1] count] < 1 && [[_arrNewsDataSorted objectAtIndex:2] count] < 1){
        _noLiveEventsView.hidden = NO;
    }else{
        _noLiveEventsView.hidden = YES;
    }
    self.title = @"Live";
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [_tblNews reloadData];
}


-(void)refreshData{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSURL *url = [[NSURL alloc] initWithString:appDelegate.liveFeed];
    DOMParser * parser = [[DOMParser alloc] init];
    parser.xml = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSArray * posts = [parser parseFeed];
    _arrNewsDataSorted = [parser sectionPostsByToday:posts];
    [self.refreshControl endRefreshing];
    if (posts) {
        [self performNewFetchedDataActionsWithDataArray:posts];
        [self.refreshControl endRefreshing];
    }
}

-(void)performNewFetchedDataActionsWithDataArray:(NSArray *)dataArray{
    // 1. Initialize the arrNewsData array with the parsed data array.
    if (_arrNewsData != nil) {
        _arrNewsData = nil;
    }
    _arrNewsData = [[NSArray alloc] initWithArray:dataArray];
    [UIApplication sharedApplication].applicationIconBadgeNumber = _arrNewsData.count;
    
    for (Post *d in _arrNewsData) {
        if ([self inFuture:d]){
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            NSDate *date;
            formatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss ZZZ";
            date = [formatter dateFromString: d.pubDate];
            // subtract 30 minutes from date and correct for GMT
            NSDate *fireDate = [date dateByAddingTimeInterval:(-30*60)];
            UILocalNotification* localNotification = [[UILocalNotification alloc] init];
            localNotification.fireDate = fireDate;
            localNotification.alertBody = [Post stringByStrippingHTML:d.title];
            NSDictionary *postDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      d.title, @"title",
                                      d.link, @"url",
                                      nil];
            localNotification.userInfo = postDict;
            localNotification.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"EST"];
            //localNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        }
    }
    
    // 2. Reload the table view.
    [self.tblNews reloadData];
    NSMutableArray *savedPosts = [[NSMutableArray alloc]init];
    for (Post *post in _arrNewsData) {
        NSDictionary *dict = @{ @"title" : [Post stringByStrippingHTML:post.title], @"pubDate" : post.pubDate, @"url" : post.link, @"description" : post.pageDescription };
        [savedPosts addObject:dict];
    }
    // 3. Save the data permanently to file.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = [paths objectAtIndex:0];
    _dataFilePath = [docDirectory stringByAppendingPathComponent:@"livedata"];
    if (![savedPosts writeToFile:_dataFilePath atomically:YES]) {
        NSLog(@"Couldn't save data.");
    }
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.livePosts = savedPosts;
}

-(void)fetchNewDataWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSURL *url = [[NSURL alloc] initWithString:appDelegate.liveFeed];
    DOMParser * parser = [[DOMParser alloc] init];
    parser.xml = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSArray * posts = [parser parseFeed];
    if (posts.count > 0) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDirectory = [paths objectAtIndex:0];
        _dataFilePath = [docDirectory stringByAppendingPathComponent:@"livedata"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:_dataFilePath]) {
            NSArray *dictsFromFile = [[NSMutableArray alloc] initWithContentsOfFile:_dataFilePath];
            NSMutableArray *obList = [[NSMutableArray alloc]init];
            for (NSDictionary *dict in dictsFromFile) {
                [obList addObject:[Post postFromDictionary:dict]];
            }
            _arrNewsData = [NSArray arrayWithArray:obList];
        }
        if (_arrNewsData.count > 0){
            Post *latestDataDict = [posts objectAtIndex:0];
            NSString *latestTitle = latestDataDict.title;
                
            Post *existingDataDict = [_arrNewsData objectAtIndex:0];
            NSString *existingTitle = existingDataDict.title;
                
            if ([latestTitle isEqualToString:existingTitle]) {
                completionHandler(UIBackgroundFetchResultNoData);
                NSLog(@"No new data found.");
            }
            else{
                [self performNewFetchedDataActionsWithDataArray:posts];
                completionHandler(UIBackgroundFetchResultNewData);
                NSLog(@"New data was fetched.");
            }
        }
    }
    else{
        completionHandler(UIBackgroundFetchResultFailed);
        NSLog(@"Failed to fetch new data.");
    }
}

-(void)fetchLiveData{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSURL *url = [[NSURL alloc] initWithString:appDelegate.liveFeed];
    DOMParser * parser = [[DOMParser alloc] init];
    parser.xml = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSArray * posts = [parser parseFeed];
    if (posts.count > 0) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDirectory = [paths objectAtIndex:0];
        _dataFilePath = [docDirectory stringByAppendingPathComponent:@"livedata"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:_dataFilePath]) {
            NSArray *dictsFromFile = [[NSMutableArray alloc] initWithContentsOfFile:_dataFilePath];
            NSMutableArray *obList = [[NSMutableArray alloc]init];
            for (NSDictionary *dict in dictsFromFile) {
                [obList addObject:[Post postFromDictionary:dict]];
            }
            _arrNewsData = [NSArray arrayWithArray:obList];
        }
        Post *latestDataDict = [posts objectAtIndex:0];
        NSString *latestTitle = latestDataDict.title;
        
        Post *existingDataDict = [_arrNewsData objectAtIndex:0];
        NSString *existingTitle = existingDataDict.title;
        
        if ([latestTitle isEqualToString:existingTitle]) {
            NSLog(@"No new data found.");
        }
        else{
            [self performNewFetchedDataActionsWithDataArray:posts];
            NSLog(@"New data was fetched.");
        }
    }
    else{
        NSLog(@"Failed to fetch new data.");
    }
    if (appDelegate.placeholderImages.count == 0){
        for (int i=1; i<=4; i++){
            [appDelegate.placeholderImages addObject:[UIImage imageNamed:@"WH_logo_3D_CMYK.png"]];
        }
    }
    for (int i=1; i<=4; i++){
        NSString *urlString = @"http://www.whitehouse.gov/sites/default/files/app/app_feature_XXX.jpg";
        urlString = [urlString stringByReplacingOccurrencesOfString:@"XXX" withString:[NSString stringWithFormat:@"%i", i]];
        NSURL *url = [NSURL URLWithString:urlString];
        [self downloadImageWithURL:url completionBlock:^(BOOL succeeded, UIImage *image) {
            if (succeeded) {
                [appDelegate.placeholderImages replaceObjectAtIndex:(i-1) withObject:image];
            }
        }];
    }
}

- (void)downloadImageWithURL:(NSURL *)url completionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if ( !error )
                               {
                                   UIImage *image = [[UIImage alloc] initWithData:data];
                                   completionBlock(YES,image);
                               } else{
                                   completionBlock(NO,nil);
                               }
                           }];
}


- (BOOL)inFuture:(Post*)post{
    BOOL future = false;
    NSDateFormatter *rssDateFormatter = [[NSDateFormatter alloc] init];
    [rssDateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss ZZ"];
    NSDate *rssDate = [rssDateFormatter dateFromString:post.pubDate];
    NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
    [dayFormatter setDateFormat:@"dd MMM yyyy"];
    NSString *todayString = [dayFormatter stringFromDate: [NSDate date]];
    NSString *otherString = [dayFormatter stringFromDate: rssDate];
    BOOL isToday;
    if([todayString isEqualToString:otherString]) {
        isToday = true;
    }
        
    NSDate *currentTime = [NSDate date];
    NSComparisonResult result;
    result = [rssDate compare:currentTime];
    if (result == NSOrderedDescending){
        future = true;
    }
    return future;
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return _arrNewsDataSorted.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [[_arrNewsDataSorted objectAtIndex:section]count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Today";
            break;
        case 1:
            return @"Upcoming Events";
            break;
        default:
            return @"Prior Events";
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([[_arrNewsDataSorted objectAtIndex:section]count] == 0) {
        return 0;
    } else {
        return 20;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:@"LiveCell" forIndexPath:indexPath];
    PostTableCell *blogCell = (PostTableCell *)cell;
    NSArray *set = [_arrNewsDataSorted objectAtIndex:indexPath.section];
    Post *post = [set objectAtIndex:indexPath.row];
    blogCell.titleLabel.text = [self parseString:post.title];
    blogCell.dateLabel.text = [NSString stringWithFormat:@"%@ - %@", post.getDate, post.getTime];
    blogCell.card.layer.shadowColor = [UIColor blackColor].CGColor;
    blogCell.card.layer.shadowRadius = 1;
    blogCell.card.layer.shadowOpacity = 0.2;
    blogCell.card.layer.shadowOffset = CGSizeMake(0.2, 2);
    blogCell.card.layer.masksToBounds = NO;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss ZZZ";
    NSDate *postDate = [formatter dateFromString: post.pubDate];
    NSDate *postDateEnd = [postDate dateByAddingTimeInterval:(+30*60)];
    NSDate *timeNow = [NSDate date];
    
    if([Post date:timeNow isBetweenDate:postDate andDate:postDateEnd])
        blogCell.happeningNowLabel.text = @"Happening Now";
    else
        blogCell.happeningNowLabel.text = @"";

    [cell setBackgroundColor:[UIColor clearColor]];
    
    return cell;
}

#define IS_IOS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
-(CGFloat) tableView: (UITableView * ) tableView heightForRowAtIndexPath: (NSIndexPath * ) indexPath {
    if (IS_IOS_8_OR_LATER)
        return UITableViewAutomaticDimension;
    else {
        NSArray *set = [_arrNewsDataSorted objectAtIndex:indexPath.section];
        Post *post = [set objectAtIndex:indexPath.row];
        NSString *title = [Post stringByStrippingHTML:post.title];
        NSError *error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\?" options:NSRegularExpressionCaseInsensitive error:&error];
        NSString *string = [regex stringByReplacingMatchesInString:title options:0 range:NSMakeRange(0, [title length]) withTemplate:@""];
        CGSize size = [string sizeWithFont:[UIFont fontWithName:@"Helvetica" size:17] constrainedToSize:CGSizeMake(_tblNews.frame.size.width, 999) lineBreakMode:NSLineBreakByWordWrapping];
        return size.height + 40;
        
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self performSegueWithIdentifier:@"LiveSegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    Post *post;
    if (_tblNews.superview == self.view){
        NSIndexPath *indexPath = [_tblNews indexPathForSelectedRow];
        NSArray *set = [_arrNewsDataSorted objectAtIndex:indexPath.section];
        post = [set objectAtIndex:indexPath.row];
    }else{
        NSArray *set = [_arrNewsDataSorted objectAtIndex:_colIndex.section];
        post = [set objectAtIndex:_colIndex.row];
    }
    WebViewController *destViewController = segue.destinationViewController;
    destViewController.url = post.link;
    NSLog(@"%@", post.link);
    destViewController.title = [self parseString:post.title];
    self.title = @"";
}

-(NSString*)parseString:(NSString*)str
{
    str  = [str stringByReplacingOccurrencesOfString:@"&ndash;" withString:@"-"];
    str  = [str stringByReplacingOccurrencesOfString:@"&rdquo;" withString:@"\""];
    str  = [str stringByReplacingOccurrencesOfString:@"&ldquo;" withString:@"\""];
    str  = [str stringByReplacingOccurrencesOfString:@"&oacute;" withString:@"o"];
    str  = [str stringByReplacingOccurrencesOfString:@"&#039;" withString:@"'"];
    return str;
}

@end
