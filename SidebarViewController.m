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
//  SidebarViewController.m
//  WhiteHouse
//

#import "SidebarViewController.h"
#import "AFHTTPRequestOperation.h"
#import "DOMParser.h"
#import "Post.h"
#import "PostTableCell.h"
#import "AppDelegate.h"
#import "ActivityViewCustomActivity.h"
#import "FavoritesViewController.h"

@interface SidebarViewController ()
@property (nonatomic, strong) NSArray *arrPhotoData;


@end

@implementation SidebarViewController

#define IS_IOS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wh-nav-menu.png"]];
    tempImageView.contentMode = UIViewContentModeScaleAspectFill;
    [tempImageView setFrame:self.tableView.frame];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundView = tempImageView;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _menuItems = appDelegate.menuItems;
    
    [_searchBar setDelegate:self];
    [self.tableView setContentInset:UIEdgeInsetsMake(150,0,0,0)];
    self.tableView.scrollEnabled = NO;
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor whiteColor]];
    
    self.revealViewController.delegate = self;
    
    for (UIView *searchBarSubview in [self.tableView subviews]) {
        
        if ([searchBarSubview conformsToProtocol:@protocol(UITextInputTraits)]) {
            
            @try {
                
                [(UITextField *)searchBarSubview setReturnKeyType:UIReturnKeyDone];
                [(UITextField *)searchBarSubview setKeyboardAppearance:UIKeyboardAppearanceAlert];
            }
            @catch (NSException * e) {
                
                // ignore exception
            }
        }
    }
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
}

- (void) viewDidAppear:(BOOL)animated  {
    [self.navTableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([tableView isEqual:_navTableView]){
        return [self.menuItems count];
    }
    else {
        return [self.searchResults count ];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if ([tableView isEqual:_navTableView]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"navCell" forIndexPath:indexPath];
        PostTableCell *navCell = (PostTableCell *)cell;
        navCell.titleLabel.text = [[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"title"];
        if (indexPath.row == 4){
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *docDirectory = [paths objectAtIndex:0];
            NSString *dataFilePath = [docDirectory stringByAppendingPathComponent:@"livedata"];
            NSArray *dictsFromFile = [[NSArray alloc]init];
            if ([[NSFileManager defaultManager] fileExistsAtPath:dataFilePath]) {
                dictsFromFile = [NSArray arrayWithContentsOfFile:dataFilePath];
            }

            navCell.dateLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)dictsFromFile.count];
            navCell.dateLabel.layer.cornerRadius = 8;
            navCell.dateLabel.layer.masksToBounds = YES;
        }else{
            [navCell.dateLabel setHidden:YES];
        }
        navCell.titleLabel.highlightedTextColor = [UIColor blackColor];
    }
    
    else { // tableView == _secondTable
        static NSString *CellIdentifier = @"Cell";
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        if (indexPath.row < _searchResults.count ){
            NSData *data = [[[_searchResults objectAtIndex:indexPath.row] objectForKey:@"title"] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
            NSString *cleanString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            NSError *error = nil;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\?" options:NSRegularExpressionCaseInsensitive error:&error];
            NSString *cleanerString = [regex stringByReplacingMatchesInString:cleanString options:0 range:NSMakeRange(0, [cleanString length]) withTemplate:@""];
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.text = cleanerString;
        }
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    return cell;
}

- (void) prepareForSegue: (UIStoryboardSegue *) segue sender: (id) sender
{
    if([segue.identifier isEqualToString:@"SearchDetail"]){
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        UINavigationController *destViewController = (UINavigationController*)segue.destinationViewController;
        destViewController.title = [[_searchResults objectAtIndex:indexPath.row] objectForKey:@"unescapedUrl"];
        SWRevealViewController *revealController = self.revealViewController;
        UINavigationController *newFrontController = [[UINavigationController alloc] initWithRootViewController:destViewController];
        [revealController pushFrontViewController:newFrontController animated:YES];
    }else{
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        UINavigationController *destViewController = (UINavigationController*)segue.destinationViewController;
        destViewController.title = [[_menuItems objectAtIndex:indexPath.row] objectForKey:@"title"];
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.activeFeed = [[_menuItems objectAtIndex:indexPath.row] objectForKey:@"feed-url"];
        
        SWRevealViewController *revealController = self.revealViewController;
        UINavigationController *newFrontController = [[UINavigationController alloc] initWithRootViewController:destViewController];
        [revealController pushFrontViewController:newFrontController animated:YES];
    }
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if([tableView isEqual:_navTableView]){
            switch ([[self.tableView indexPathForSelectedRow]row])
            {
                case 0:
                {
                    [self performSegueWithIdentifier:@"BlogSegue" sender:self];
                    break;
                }case 1:
                {
                    [self performSegueWithIdentifier:@"BriefingRoomSegue" sender:self];
                    break;
                }case 2:
                {
                    [self performSegueWithIdentifier:@"PhotoSegue" sender:self];
                    break;
                }case 3:
                {
                    [self performSegueWithIdentifier:@"VideoSegue" sender:self];
                    break;
                }
                case 4:
                {
                    [self performSegueWithIdentifier:@"LiveSegue" sender:self];
                    break;
                }case 5:
                {
                    [self performSegueWithIdentifier:@"FavoritesSegue" sender:self];
                }
            }
        [self.revealViewController setFrontViewPosition:FrontViewPositionLeft];
    }else if ([tableView isEqual:_searchTableView]) {
        [self performSegueWithIdentifier:@"SearchDetail" sender:self];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath; {
    
    if (IS_IOS_8_OR_LATER) {
        return UITableViewAutomaticDimension;
    }
    else {
        if ([tableView isEqual:_navTableView]){
            return 45.0;
        }
        else {
            if (indexPath.row < _searchResults.count ){
                NSData *data = [[[_searchResults objectAtIndex:indexPath.row] objectForKey:@"title"] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
                NSString *cleanString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                NSError *error = nil;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\?" options:NSRegularExpressionCaseInsensitive error:&error];
                NSString *cleanerString = [regex stringByReplacingMatchesInString:cleanString options:0 range:NSMakeRange(0, [cleanString length]) withTemplate:@""];
                CGSize size = [cleanerString sizeWithFont:[UIFont fontWithName:@"Helvetica" size:17] constrainedToSize:CGSizeMake(280, 999) lineBreakMode:NSLineBreakByWordWrapping];
                return size.height + 20;
            }
            else{
                return 45.0;
            }
        }
    }
}

#pragma search

-(void)keyboardDidShow:(NSNotification*)notification
{
    float viewHeight = _navTableView.frame.size.height;
    CGFloat keyboardHeight = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    CGFloat keyboardWidth = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.width;
    if (!IS_IOS_8_OR_LATER && (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) ) {
        [_searchTableView setFrame:CGRectMake(0.0, 50.0, 320.0, (viewHeight - keyboardWidth - 70))];
    }
    else {
        [_searchTableView setFrame:CGRectMake(0.0, 50.0, 320.0, (viewHeight - keyboardHeight - 70))];
    }
}

-(void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    int height = _navTableView.frame.size.height;
    _searchTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 50.0, 320.0, height) style:UITableViewStylePlain];
    _searchTableView.dataSource = self;
    _searchTableView.delegate = self;
    _searchTableView.hidden = true;
    
    [self.revealViewController setFrontViewPosition:FrontViewPositionRightMost];
    [_searchBar setShowsCancelButton:YES animated:YES];
    
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"WHITEHOUSE-MENU-bg.png"]];
    tempImageView.contentMode = UIViewContentModeScaleAspectFill;
    [tempImageView setFrame:_searchTableView.frame];
    
    _searchTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    _searchTableView.backgroundView = tempImageView;
    [self.view addSubview:_searchTableView];
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller{
    [self.searchDisplayController.searchResultsTableView setDelegate:self];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [_searchTableView removeFromSuperview];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    searchBar.text = @"";
    [searchBar setShowsCancelButton:NO animated:YES];
    [_searchTableView removeFromSuperview];
    [searchBar resignFirstResponder];
    [self.revealViewController setFrontViewPosition:FrontViewPositionRight];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    [searchBar setShowsCancelButton:NO animated:YES];
    [_searchTableView removeFromSuperview];
    [searchBar resignFirstResponder];
    [self.revealViewController setFrontViewPosition:FrontViewPositionRight];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (_searchTableView.hidden){
        _searchTableView.hidden = false;
    }
    // 1
    NSString *searchQuery = [NSString stringWithFormat:@"http://search.usa.gov/api/search.json?affiliate=wh&index=web&query='%@'",searchText];
    NSURL *url = [NSURL URLWithString:searchQuery];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // 2
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        // 3
        _searchResults = responseObject[@"results"];
        NSLog(@"json is:%@", responseObject);
        [_searchTableView reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Nothing found");
    }];
    
    // 5
    [operation start];
}

-(void)presentLive{
    [self performSegueWithIdentifier:@"LiveSegue" sender:self];
}

- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position
{
    if (revealController.frontViewPosition == FrontViewPositionRight) {
        UIView *lockingView = [UIView new];
        lockingView.translatesAutoresizingMaskIntoConstraints = NO;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:revealController action:@selector(revealToggle:)];
        [lockingView addGestureRecognizer:tap];
        [lockingView addGestureRecognizer:revealController.panGestureRecognizer];
        [lockingView setTag:1000];
        [revealController.frontViewController.view addSubview:lockingView];
        
        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(lockingView);
        
        [revealController.frontViewController.view addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"|[lockingView]|"
                                                 options:0
                                                 metrics:nil
                                                   views:viewsDictionary]];
        [revealController.frontViewController.view addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[lockingView]|"
                                                 options:0
                                                 metrics:nil
                                                   views:viewsDictionary]];
        [lockingView sizeToFit];
    }
    else
        [[revealController.frontViewController.view viewWithTag:1000] removeFromSuperview];
}

@end
