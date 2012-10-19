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
//  WHReaderPanelView.m
//  WhiteHouseApp
//
//

#import "WHReaderPanelView.h"

#import <QuartzCore/QuartzCore.h>
#import "NimbusNetworkImage.h"

@interface WHReaderPanelView ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UILabel *dateLabel;

// The image view that we will use to show our custom photo
@property (nonatomic, strong) NINetworkImageView *imageView;
@end


@implementation WHReaderPanelView

@synthesize feedItem = _feedItem;
@synthesize showAuthor;

@synthesize titleLabel = _titleLabel;
@synthesize dateLabel = _dateLabel;
@synthesize textLabel = _textLabel;

@synthesize imageView;

- (void)setFeedItem:(WHFeedItem *)feedItem
{
    _feedItem = feedItem;
    
    _titleLabel.text = feedItem.title;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    NSString *dateString = [dateFormatter stringFromDate:feedItem.pubDate];
    
    self.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", feedItem.title, dateString];
    
    if (self.showAuthor) {
        _dateLabel.text = [NSString stringWithFormat:@"%@ | %@", feedItem.creator, dateString];
    } else {
        _dateLabel.text = dateString;
    }
    
    self.imageView.image = [UIImage imageNamed:@"photo-placeholder"];
    
    WHMediaElement *thumb = [self.feedItem bestThumbnailForWidth:(self.bounds.size.width + 50)];
    if (thumb) {
        self.imageView.hidden = NO;
        self.textLabel.hidden = YES;
        
        [self.imageView setPathToNetworkImage:[thumb.URL absoluteString]];
    } else {
        self.textLabel.hidden = NO;
        self.imageView.hidden = YES;
        
        NSArray *lines = [feedItem.descriptionText componentsSeparatedByString:@"\n"];
        NSMutableArray *trimmedLines = [NSMutableArray arrayWithCapacity:lines.count];
        NSCharacterSet *trimChars = [NSCharacterSet whitespaceCharacterSet];
        for (NSString *line in lines) {
            [trimmedLines addObject:[line stringByTrimmingCharactersInSet:trimChars]];
        }
        _textLabel.text = [trimmedLines componentsJoinedByString:@"\n"];
    }
    
    [self setNeedsLayout];
}

#define PANEL_PADDING 24
#define LABEL_MARGIN 4

- (UILabel *)createLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(self.bounds, PANEL_PADDING, PANEL_PADDING)];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.numberOfLines = 0;
    [self addSubview:label];
    return label;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.isAccessibilityElement = YES;
        
        self.backgroundColor = [UIColor whiteColor];
        CALayer *layer = self.layer;
        layer.borderColor = [[UIColor colorWithWhite:0.9 alpha:1.0] CGColor];
        layer.borderWidth = 1.0;
        
        self.imageView = [[NINetworkImageView alloc] initWithFrame:self.bounds];
        self.imageView.clipsToBounds = YES;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.imageView];
        
        self.titleLabel = [self createLabel];
        self.titleLabel.backgroundColor = self.backgroundColor;
        self.titleLabel.font = [WHStyle headingFontWithSize:20];
        self.titleLabel.textColor = [WHStyle primaryColor];
        
        self.dateLabel = [self createLabel];
        self.dateLabel.font = [WHStyle detailFontWithSize:12];
        self.dateLabel.textColor = [UIColor grayColor];
        
        self.textLabel = [self createLabel];
        self.textLabel.font = [WHStyle detailFontWithSize:16];
    }
    return self;
}

- (void)positionView:(UIView *)southView underView:(UIView *)northView
{
    [northView sizeToFit];
    CGRect southFrame = southView.frame;
    southFrame.origin.y = CGRectGetMaxY(northView.frame) + LABEL_MARGIN;
    southView.frame = southFrame;
}

- (void)layoutSubviews
{
    CALayer *layer = self.layer;
    layer.shadowOffset = CGSizeMake(0, 3.0);
    layer.shadowOpacity = 0.05;
    layer.shadowRadius = 3.0;
    CGPathRef shadowPath = CGPathCreateWithRect(self.bounds, nil);
    layer.shadowPath = shadowPath;
    CGPathRelease(shadowPath);
    
    CGRect resetFrame = CGRectInset(self.bounds, PANEL_PADDING, PANEL_PADDING);
    self.titleLabel.frame = self.dateLabel.frame = self.textLabel.frame = resetFrame;
    [self.titleLabel sizeToFit];
    [self.dateLabel sizeToFit];
    
    if (self.imageView.hidden) {
        [self positionView:self.dateLabel underView:self.titleLabel];
        [self positionView:self.textLabel underView:self.dateLabel];
        [self.textLabel sizeToFit];
        CGRect textFrame = CGRectIntersection(self.textLabel.frame, resetFrame);
        self.textLabel.frame = textFrame;
    } else {
        CGFloat barHeight = self.dateLabel.bounds.size.height + self.titleLabel.bounds.size.height + (PANEL_PADDING * 2) + LABEL_MARGIN;
        CGFloat h = self.bounds.size.height;
        CGFloat w = self.bounds.size.width;
        
        self.titleLabel.frame = CGRectOffset(self.titleLabel.frame, 0, h - barHeight);
        [self positionView:self.dateLabel underView:self.titleLabel];
        
        CGRect imageFrame = CGRectMake(0, 0, w, h - barHeight);
        self.imageView.frame = CGRectInset(imageFrame, 1, 1);
    }
    
    [super layoutSubviews];
}

@end
