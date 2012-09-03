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
//  WHPhotoAlbumScrollView.m
//  WhiteHouseApp
//
//

#import "WHCaptionedPhotoView.h"


@interface WHCaptionedPhotoView ()
@property (nonatomic, strong) UIView *captionWell;
@property (nonatomic, strong) UILabel *captionLabel;
@end


@implementation WHCaptionedPhotoView

@synthesize captionWell = _captionWell;
@synthesize captionLabel = _captionLabel;


static UIEdgeInsets kWellPadding;


+ (void)initialize
{
    // bottom padding takes toolbar into account
    kWellPadding = UIEdgeInsetsMake(8, 8, 44 + 8, 8);
}


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.captionWell = [[UIView alloc] initWithFrame:self.bounds];
        _captionWell.autoresizingMask = (UIViewAutoresizingFlexibleWidth
                                         | UIViewAutoresizingFlexibleTopMargin);
        _captionWell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75];
        
        self.captionLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _captionLabel.backgroundColor = [UIColor clearColor];
        _captionLabel.lineBreakMode = UILineBreakModeTailTruncation;
        _captionLabel.numberOfLines = 0;
        _captionLabel.font = [WHStyle detailFontWithSize:12];
        _captionLabel.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
        _captionLabel.shadowOffset = CGSizeMake(0, 1);
        _captionLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
        
        UIView* topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 1)];
        topLine.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        topLine.backgroundColor = [UIColor darkGrayColor];

        
        [_captionWell addSubview:topLine];
        [_captionWell addSubview:_captionLabel];
        [self addSubview:_captionWell];
    }
    
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat availableWidth = self.bounds.size.width - kWellPadding.left - kWellPadding.right;
    
    CGSize labelSize =  [self.captionLabel.text sizeWithFont:self.captionLabel.font
                                           constrainedToSize:CGSizeMake(availableWidth, CGFLOAT_MAX)
                                               lineBreakMode:self.captionLabel.lineBreakMode];
    CGFloat wellHeight = labelSize.height + kWellPadding.top + kWellPadding.bottom;
    self.captionWell.frame = CGRectMake(0, self.bounds.size.height - wellHeight,
                                        self.bounds.size.width, wellHeight);
    self.captionLabel.frame = UIEdgeInsetsInsetRect(self.captionWell.bounds, kWellPadding);
}


- (void)setCaption:(NSString *)text
{
    if (_captionLabel.text != text) {
        _captionLabel.text = text;
        [self setNeedsLayout];
    }
}


- (void)setCaptionHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (animated) {
        [UIView beginAnimations:NSStringFromClass([self class]) context:nil];
    }
    
    _captionWell.alpha = (hidden ? 0.0 : 1.0);
    
    if (animated) {
        [UIView commitAnimations];
    }
}

@end
