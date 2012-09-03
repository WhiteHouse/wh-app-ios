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
//  WHBlogViewController.m
//  WhiteHouseApp
//
//

#import "WHBlogViewController.h"

#import "DTCustomColoredAccessory.h"
#import "SVPullToRefresh.h"

NSString* PluralizeTimeUnits(NSString *unit, int n)
{
    NSString *futureFormat = NSLocalizedString(@"RelativeDateFutureFormat", @"in %i %@");
    NSString *pastFormat = NSLocalizedString(@"RelativeDatePastFormat", @"%i %@ ago");
    
    NSString *format = ((n < 0) ? futureFormat : pastFormat);
    int count = ABS(n);
    
    // construct a key for the localized time unit, like SingularHour, or PluralMinute, etc.
    NSString *unitKey = [NSString stringWithFormat:@"%@%@", (count == 1) ? @"Singular" : @"Plural", unit];
    NSString *unitText = NSLocalizedString(unitKey, nil);
    return [NSString stringWithFormat:format, count, unitText];
}

#define MAX_HOURS 6

NSString* RelativeDateString(NSDate *date)
{
    NSCalendar *cal = [NSCalendar autoupdatingCurrentCalendar];
    NSInteger flags = NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit;
    NSDateComponents *components = [cal components:flags fromDate:date toDate:[NSDate date] options:0];
    
    if (MAX_HOURS < components.hour) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.timeStyle = NSDateFormatterShortStyle;
        return [[formatter stringFromDate:date] uppercaseString];
    } else if (components.hour) {
        return PluralizeTimeUnits(@"Hour", components.hour);
    } else if (components.minute) {
        return PluralizeTimeUnits(@"Minute", components.minute);
    } else {
        return PluralizeTimeUnits(@"Second", components.second);
    }
}


@implementation WHBlogViewController


@synthesize postsByDate;


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView addPullToRefreshWithActionHandler:^{
        [self.feed fetch];
    }];
}


- (void)updateFeedItems:(NSSet *)feedItems
{
    [self.tableView.pullToRefreshView stopAnimating];
    self.tableView.pullToRefreshView.lastUpdatedDate = self.feed.lastUpdatedDate;
    
    NSArray *orderedItems = [self sortFeedItems:feedItems.allObjects];
    self.postsByDate = [orderedItems partitionedArrayUsingBlock:^(WHFeedItem *obj) {
        return DayFromDate(obj.pubDate);
    }];

    [super updateFeedItems:feedItems];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.postsByDate.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    WHFeedItem *item = [[self.postsByDate objectAtIndex:section] firstObject];
    NSDate *day = DayFromDate(item.pubDate);
    NSDate *today = DayFromDate([NSDate date]);
    
    NSCalendar *cal = [NSCalendar autoupdatingCurrentCalendar];
    NSDateComponents *components = [cal components:NSDayCalendarUnit fromDate:day toDate:today options:NSWrapCalendarComponents];
    
    if (components.day == 0) {
        return NSLocalizedString(@"Today", @"Today");
    } else if (components.day == 1) {
        return NSLocalizedString(@"Yesterday", @"Yesterday");
    } else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        return [dateFormatter stringFromDate:item.pubDate];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.postsByDate objectAtIndex:section] count];
}

- (WHFeedItem *)feedItemForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self.postsByDate objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
}

- (NSURL *)thumbnailURLForItem:(WHFeedItem *)item
{
    return [item bestThumbnailForWidth:[UIScreen mainScreen].bounds.size.width].URL;
}

#define ROW_HEIGHT 74
#define PHOTO_HEIGHT 198
#define PHOTO_V_PADDING 0
#define PHOTO_ROW_HEIGHT (PHOTO_HEIGHT + PHOTO_V_PADDING + PHOTO_V_PADDING)
#define CELL_PADDING 8
#define CELL_PADDING_RIGHT 28.0
#define TITLE_FONT_SIZE 16
#define DATE_FONT_SIZE (TITLE_FONT_SIZE - 4)
#define DATE_HEIGHT 20
#define DATE_Y CELL_PADDING
#define TITLE_Y (DATE_Y + DATE_HEIGHT)

- (CGSize)sizeForTitleText:(NSString *)text
{
    CGFloat titleWidth = self.view.bounds.size.width - (CELL_PADDING + CELL_PADDING_RIGHT);
    return [text sizeWithFont:[WHStyle headingFontWithSize:TITLE_FONT_SIZE] constrainedToSize:CGSizeMake(titleWidth, 1000) lineBreakMode:UILineBreakModeWordWrap];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WHFeedItem *item = [self feedItemForRowAtIndexPath:indexPath];
    if (!NIIsPad() && item.mediaThumbnails.count) {
        return PHOTO_ROW_HEIGHT;
    }
    
    CGSize newSize = [self sizeForTitleText:item.title];
    return TITLE_Y + newSize.height + CELL_PADDING;
}


enum {
    TAG_UNUSED,
    TAG_TITLE,
    TAG_DATE,
    TAG_IMAGE,
    TAG_LABEL_CONTAINER,
    TAG_SPINNER,
    TAG_FAIL
};


#define HEADER_PADDING 4
#define HEADER_HEIGHT (TITLE_FONT_SIZE + HEADER_PADDING + HEADER_PADDING)

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return HEADER_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, HEADER_HEIGHT)];
    headerView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"section-bar"]];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(HEADER_PADDING, HEADER_PADDING, 320, TITLE_FONT_SIZE)];
    label.backgroundColor = [UIColor clearColor];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.font = [WHStyle detailFontWithSize:14];
    label.textColor = [UIColor blackColor];
    label.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    label.shadowOffset = CGSizeMake(0, 1);
    [headerView addSubview:label];
    return headerView;
}


- (NINetworkImageView *)imageViewForCell:(UITableViewCell *)cell
{
    return (NINetworkImageView *)[cell viewWithTag:TAG_IMAGE];
}


static NSString *CellIdentifier = @"PhotoCell";


- (UITableViewCell *)createMediaCell
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    NINetworkImageView *imageView = [[NINetworkImageView alloc] initWithImage:[UIImage imageNamed:@"photo-placeholder"]];
    [imageView sizeToFit];
    imageView.tag = TAG_IMAGE;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.delegate = self;
    cell.backgroundView = imageView;
    
    CGRect barFrame = CGRectMake(0, PHOTO_V_PADDING + PHOTO_HEIGHT - ROW_HEIGHT, 320, ROW_HEIGHT);
    UIView *blackBar = [[UIView alloc] initWithFrame:barFrame];
    blackBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    blackBar.tag = TAG_LABEL_CONTAINER;
    blackBar.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.75];
    [cell.contentView addSubview:blackBar];
    
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:blackBar.frame];
    cell.selectedBackgroundView.backgroundColor = [UIColor colorWithHue:(211.0 / 360.0) saturation:0.99 brightness:0.93 alpha:0.8];
    
    DTCustomColoredAccessory *arrow = [DTCustomColoredAccessory accessoryWithColor:[UIColor whiteColor]];
    arrow.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    CGRect arrowFrame = arrow.frame;
    arrowFrame.origin = CGPointMake(297, 30);
    arrow.frame = arrowFrame;
    [blackBar addSubview:arrow];
    
    CGRect titleFrame = CGRectMake(CELL_PADDING, TITLE_Y, 320 - CELL_PADDING - CELL_PADDING_RIGHT, TITLE_FONT_SIZE * 2);
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:titleFrame];
    // titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.tag = TAG_TITLE;
    titleLabel.font = [WHStyle headingFontWithSize:TITLE_FONT_SIZE];
    titleLabel.textColor = [UIColor colorFromRGBHexString:AppConfig(@"PhotoPostTitleColor")];
    titleLabel.numberOfLines = 0;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.highlightedTextColor = [UIColor whiteColor];
    [blackBar addSubview:titleLabel];
    
    UILabel *dateView = [[UILabel alloc] initWithFrame:CGRectMake(CELL_PADDING, CELL_PADDING, 320, DATE_HEIGHT)];
    dateView.tag = TAG_DATE;
    dateView.font = [WHStyle detailFontWithSize:DATE_FONT_SIZE];
    dateView.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    dateView.backgroundColor = [UIColor clearColor];
    dateView.highlightedTextColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    [blackBar addSubview:dateView];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.hidesWhenStopped = YES;
    spinner.tag = TAG_SPINNER;
    CGRect spinnerFrame = spinner.frame;
    spinnerFrame.origin.x = (int)(imageView.frame.size.width / 2) - (int)(spinnerFrame.size.width / 2);
    spinnerFrame.origin.y = (int)(imageView.frame.size.height / 2) - (int)(spinnerFrame.size.height / 2) - 20;
    spinner.frame = spinnerFrame;
    [cell.contentView addSubview:spinner];
    
    UILabel *failLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    failLabel.textAlignment = UITextAlignmentCenter;
    CGPoint failCenter = cell.contentView.center;
    failCenter.y += 1;
    failLabel.center = failCenter;
    failLabel.autoresizingMask = UIViewAutoresizingFlexibleMargins;
    failLabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:40];
    failLabel.textColor = [UIColor whiteColor];
    failLabel.shadowColor = [UIColor darkGrayColor];
    failLabel.backgroundColor = [UIColor clearColor];
    failLabel.shadowOffset = CGSizeMake(0, -1);
    failLabel.hidden = YES;
    failLabel.tag = TAG_FAIL;
    failLabel.alpha = 0.3;
    failLabel.text = @"?";
    
    [cell.contentView addSubview:failLabel];
    
    return cell;
}


- (void)configureMediaCell:(UITableViewCell *)cell forFeedItem:(WHFeedItem *)item
{
    NINetworkImageView *imageView = [self imageViewForCell:cell];
    imageView.image = imageView.initialImage;
    
    [imageView setPathToNetworkImage:[[self thumbnailURLForItem:item] absoluteString]];
    
    UIView *failView = [cell viewWithTag:TAG_FAIL];
    if (imageView.image) {
        failView.hidden = YES;
    } else {
        failView.hidden = NO;
    }
    
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[cell viewWithTag:TAG_SPINNER];
    if (imageView.isLoading) {
        [spinner startAnimating];
    } else {
        [spinner stopAnimating];
    }
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:TAG_TITLE];
    CGSize titleSize = [self sizeForTitleText:item.title];
    titleLabel.frame = CGRectMake(CELL_PADDING, TITLE_Y, titleSize.width, titleSize.height);
    titleLabel.text = item.title;
    
    UIView *labelContaier = [cell viewWithTag:TAG_LABEL_CONTAINER];
    CGFloat containerHeight = TITLE_Y + titleSize.height + CELL_PADDING;
    labelContaier.frame = CGRectMake(0, PHOTO_ROW_HEIGHT - containerHeight, 320, containerHeight);
    
    UILabel *dateView = (UILabel *)[cell viewWithTag:TAG_DATE];
    dateView.text = RelativeDateString(item.pubDate);
}


- (UITableViewCell *)photoCellForItem:(WHFeedItem *)item
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [self createMediaCell];
    }
    
    [self configureMediaCell:cell forFeedItem:item];
    
    return cell;
}


- (void)configureCell:(UITableViewCell *)cell forFeedItem:(WHFeedItem *)item
{
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:TAG_TITLE];
    CGSize titleSize = [self sizeForTitleText:item.title];
    titleLabel.frame = CGRectMake(CELL_PADDING, TITLE_Y, titleSize.width, titleSize.height);
    titleLabel.text = item.title;
    
    UILabel *dateView = (UILabel *)[cell viewWithTag:TAG_DATE];
    dateView.text = RelativeDateString(item.pubDate);
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WHFeedItem *item = [self feedItemForRowAtIndexPath:indexPath];
    
    if (!NIIsPad() && item.mediaThumbnails.count) {
        return [self photoCellForItem:item];
    }
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.adjustsFontSizeToFitWidth = YES;
        titleLabel.tag = TAG_TITLE;
        titleLabel.font = [WHStyle headingFontWithSize:TITLE_FONT_SIZE];
        titleLabel.textColor = [WHStyle primaryColor];
        titleLabel.numberOfLines = 0;
        titleLabel.highlightedTextColor = [UIColor whiteColor];
        [cell.contentView addSubview:titleLabel];
        
        UILabel *dateView = [[UILabel alloc] initWithFrame:CGRectMake(CELL_PADDING, CELL_PADDING, 320, DATE_HEIGHT)];
        dateView.tag = TAG_DATE;
        dateView.font = [WHStyle detailFontWithSize:TITLE_FONT_SIZE - 4];
        dateView.textColor = [UIColor grayColor];
        dateView.highlightedTextColor = [UIColor colorWithWhite:0.8 alpha:1.0];
        [cell.contentView addSubview:dateView];
    }
    
    // Configure the cell...
    
    [self configureCell:cell forFeedItem:item];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    WHFeedItem *item = [self feedItemForRowAtIndexPath:indexPath];
    [self displayFeedItem:item];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    DebugLog(@"blog view should rotate?");
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}


- (UITableViewCell *)cellForImageView:(UIView *)imageView
{
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        if (imageView == [self imageViewForCell:cell]) {
            return cell;
        }
    }
    
    return nil;
}


- (void)networkImageView:(NINetworkImageView *)imageView didLoadImage:(UIImage *)image
{
    UITableViewCell *cell = [self cellForImageView:imageView];
    if (cell) {
        UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[cell viewWithTag:TAG_SPINNER];
        [spinner stopAnimating];
    }
}


- (void)networkImageView:(NINetworkImageView *)imageView didFailWithError:(NSError *)error
{
    UITableViewCell *cell = [self cellForImageView:imageView];
    if (cell) {
        UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[cell viewWithTag:TAG_SPINNER];
        [spinner stopAnimating];
        UIView *failView = [cell viewWithTag:TAG_FAIL];
        failView.hidden = NO;
    }
}


@end
