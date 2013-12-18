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
//  WHRootMenuViewController.m
//  WhiteHouseApp
//
//

#import "WHRootMenuViewController.h"

#import "DTCustomColoredAccessory.h"
#import "WHRevealViewController.h"
#import "NimbusWebController.h"
#import "WHTrendyView.h"
#import "WHMenuItem.h"


@implementation NSString (USASearchHighlighting)
- (NSString *)stringByRemovingSearchHighlight
{
    // remove USA Search's funky unicode highlight start/end characters \ue000 and \ue001 respectively
    // Obj-C string literals for them are like so:
    return [[self stringByReplacingOccurrencesOfString:@"\U0000e000" withString:@""] stringByReplacingOccurrencesOfString:@"\U0000e001" withString:@""];
}
@end


@interface WHRootMenuViewController ()
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) WHSearchController *searchController;
@property (nonatomic, strong) UISearchDisplayController *mySearchDisplayController;
@property (nonatomic, readonly) WHRevealViewController *revealViewController;
@end

@implementation WHRootMenuViewController

@synthesize menuItems = _menuItems;
@synthesize searchBar = _searchBar;
@synthesize tableView = _tableView;
@synthesize searchController = _searchController;
@synthesize mySearchDisplayController;
@synthesize revealViewController;
@synthesize selectedMenuItemIndex = _selectedMenuItemIndex;


- (void)setSelectedMenuItemIndex:(NSUInteger)selectedMenuItemIndex
{
    _selectedMenuItemIndex = selectedMenuItemIndex;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selectedMenuItemIndex inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    self.revealViewController.contentViewController = [(self.menuItems)[indexPath.row] viewController];
    [self.revealViewController setMenuVisible:NO wantsFullWidth:NO];
}


- (UIColor *)cellBGColor;
{
    return [UIColor colorWithWhite:0.47 alpha:1.0];
}

- (void)styleTableView:(UITableView *)tableView
{
    tableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UISearchBar *bar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
    [bar sizeToFit];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    bar.tintColor = [UIColor colorWithWhite:(121.0/255.0) alpha:1.0];
    
    bar.placeholder = NSLocalizedString(@"SearchPlaceholder", @"Search WhiteHouse.gov");
    [self.view addSubview:bar];
    
    self.searchBar = bar;
    
    /*
     initializing a search display controller sets the contents controller's
     self.searchDisplayController property, BUT it does not hold on to it, so
     we need a second strong reference to it in order for delegate methods to
     work at all...
    */
    self.mySearchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.mySearchDisplayController.delegate = self;
    self.mySearchDisplayController.searchResultsDataSource = self;
    self.mySearchDisplayController.searchResultsDelegate = self;
    
    // squish the table view frame down by the height of the search bar
    CGRect tableViewFrame = self.view.bounds;
    tableViewFrame.origin.y += self.searchBar.bounds.size.height;
    tableViewFrame.size.height -= tableViewFrame.origin.y;
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.scrollEnabled = NO;
    [self styleTableView:tableView];
    
    self.tableView = tableView;
    
    WHTrendyView *bg = [[WHTrendyView alloc] initWithFrame:self.view.bounds];
    bg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    bg.autoresizingMask = UIViewAutoresizingFlexibleDimensions;
    
    UIImageView *seal = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav-branding"]];
    seal.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    seal.contentMode = UIViewContentModeScaleAspectFit;
    
    int w = tableView.bounds.size.width;
    seal.frame = CGRectInset(CGRectMake(0, 200, w, 200), 3, 3);
    seal.alpha = 0.1;
    [self.view addSubview:seal];
    [bg addSubview:seal];
    
    tableView.backgroundView = bg;
    [self.view addSubview:tableView];
}

- (void)viewDidUnload
{
    self.searchBar = nil;
    self.tableView = nil;
    [super viewDidUnload];
}


- (WHRevealViewController *)revealViewController
{
    return (WHRevealViewController *)self.parentViewController;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        return self.menuItems.count;
    } else {
        return self.searchController.results.count;
    }
}

#define CELL_IDENT_MENU @"MenuCell"
#define CELL_IDENT_SEARCH @"Search"

- (UITableViewCell *)searchResultsTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENT_SEARCH];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELL_IDENT_SEARCH];
        cell.textLabel.font = [WHStyle headingFontWithSize:16];
        cell.textLabel.textColor = [WHStyle primaryColor];
        cell.textLabel.numberOfLines = 2;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSDictionary *searchItem = (self.searchController.results)[indexPath.row];
    cell.textLabel.text = [searchItem[@"title"] stringByRemovingSearchHighlight];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self searchResultsTableView:tableView cellForRowAtIndexPath:indexPath];
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENT_MENU];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELL_IDENT_MENU];
        
        cell.backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
        cell.backgroundView.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor darkGrayColor];
        // don't change on highlight
        cell.textLabel.highlightedTextColor = cell.textLabel.textColor;
        cell.textLabel.font = [WHStyle headingFontWithSize:22];
        
        UIView *bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, cell.bounds.size.height - 1, 320, 1)];
        bottomBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        bottomBar.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
        [cell addSubview:bottomBar];
        
        UIView *selectedView = [[UIView alloc] initWithFrame:cell.bounds];
        selectedView.autoresizingMask = UIViewAutoresizingFlexibleDimensions;
        selectedView.backgroundColor = bottomBar.backgroundColor;
        cell.selectedBackgroundView = selectedView;
        
        // use our text color for the disclosure indicator
        cell.accessoryView = [DTCustomColoredAccessory accessoryWithColor:cell.textLabel.textColor];
    }
    
    WHMenuItem *item = (self.menuItems)[indexPath.row];
    cell.textLabel.text = item.title;
    
    return cell;
}

- (void)revealToggle
{
    [self.revealViewController setMenuVisible:YES wantsFullWidth:NO];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DebugLog(@"selected row %i", indexPath.row);
    if (tableView == self.tableView) {
        self.revealViewController.contentViewController = [(self.menuItems)[indexPath.row] viewController];
        [self.revealViewController setMenuVisible:NO wantsFullWidth:NO];
    } else {
        NIWebController *browser = [[NIWebController alloc] initWithNibName:nil bundle:nil];
        
        UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(revealToggle)];
        browser.navigationItem.leftBarButtonItem = menuButton;
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:browser];
        [nav.view layoutSubviews];
        
        self.revealViewController.contentViewController = nav;

        [self.searchDisplayController setActive:NO];
        [self.revealViewController setMenuVisible:NO wantsFullWidth:NO];
        
        NSDictionary *searchItem = (self.searchController.results)[indexPath.row];
        NSURL *theURL = [NSURL URLWithString:searchItem[@"unescapedUrl"]];
        DebugLog(@"theURL = %@", theURL);
        
        [browser openURL:theURL];
    }
}

#pragma mark - search delegate

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    DebugLog(@"search will begin");
    [self.revealViewController setMenuVisible:YES wantsFullWidth:YES];
}


- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    DebugLog(@"search will end");
    [self.revealViewController setMenuVisible:YES wantsFullWidth:NO];
}


- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
}


- (void)search:(NSString *)query
{
    self.searchController = [[WHSearchController alloc] initWithDelegate:self];
    self.searchController.query = query;
    [self.searchController fetchResults];
    [self.searchController fetchResults];
    [self.searchController fetchResults];
    [self.searchController fetchResults];
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    /*
     cancel any delayed search (set up on the next line) so that it is executed 
     automatically when the user pauses after typing a query
     */
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    // set up the delayed search callback
    [self performSelector:@selector(search:) withObject:searchString afterDelay:0.5];
    
    return NO;
}

# pragma mark - search controller delegate methods

- (void)searchControllerDidFindResults:(WHSearchController *)searchController
{
    DebugLog(@"got results");
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (void)searchController:(WHSearchController *)searchController didFailWithError:(NSError *)error
{
    DebugLog(@"oh noes");
}

@end
