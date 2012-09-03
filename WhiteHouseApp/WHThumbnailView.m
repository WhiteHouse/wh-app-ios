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
//  WHPhotoFeedItemView.m
//  WhiteHouseApp
//
//

#import "WHThumbnailView.h"

#import "NimbusNetworkImage.h"
#import <QuartzCore/QuartzCore.h>

@interface WHThumbnailView ()
@property (nonatomic, strong) NINetworkImageView *imageView;
@end


@implementation WHThumbnailView

@synthesize feedItem = _feedItem;
@synthesize imageView = _imageView;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor whiteColor];
        
        CALayer *layer = self.layer;
        
        // add a gradient sublayer to the layer
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.bounds;
        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:0.9 alpha:1.0] CGColor], (id)[[UIColor whiteColor] CGColor], nil];
        [layer insertSublayer:gradient atIndex:0];
        
        // set up the drop shadow
        layer.shadowOffset = CGSizeMake(0, 3.0);
        layer.shadowOpacity = 0.2;
        layer.shadowRadius = 3.0;
        CGPathRef shadowPath = CGPathCreateWithRect(layer.bounds, NULL);
        layer.shadowPath = shadowPath;
        CGPathRelease(shadowPath);
        
        self.imageView = [[NINetworkImageView alloc] initWithFrame:CGRectInset(self.bounds, 6, 6)];
        self.imageView.backgroundColor = [UIColor grayColor];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        
        [self addSubview:self.imageView];
    }
    
    return self;
}


- (void)setFeedItem:(WHFeedItem *)feedItem
{
    _feedItem = feedItem;
    self.imageView.image = nil;    
    
    if (feedItem) {
        WHMediaElement *thumb = [feedItem bestThumbnailForWidth:self.imageView.bounds.size.width];
        [self.imageView setPathToNetworkImage:[thumb.URL absoluteString]];
    }
}


@end
