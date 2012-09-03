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
//  WHLiveBarView.m
//  WhiteHouseApp
//
//

#import "WHPullDownView.h"

@interface WHPullDownView ()
@property (nonatomic, assign) CGPoint initialTouchPoint;
@property (nonatomic, assign) CGPoint lastTouchPoint;
@end

@implementation WHPullDownView

@synthesize contentView = _contentView;
@synthesize handleView = _handleView;

@synthesize initialTouchPoint;
@synthesize lastTouchPoint;

- (id)initWithContentView:(UIView *)contentView handleView:(UIView *)handleView
{
    self = [super initWithFrame:handleView.bounds];
    if (self) {
        [self setClipsToBounds:YES];
        
        self.contentView = contentView;
        contentView.frame = CGRectOffset(contentView.bounds, 0, -(contentView.bounds.size.height));
        contentView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:contentView];
        
        self.handleView = handleView;
        handleView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:handleView];
    }
    return self;
}

- (CGRect)openFrame
{
    return CGRectUnion(self.handleView.bounds, CGRectOffset(self.contentView.bounds, 0, self.handleView.bounds.size.height));
}

- (BOOL)isOpen
{
    return !CGSizeEqualToSize(self.bounds.size, self.handleView.bounds.size);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    DebugLog(@"touchy touchy");
    
    UITouch *touch = [[event allTouches] anyObject];
    self.lastTouchPoint = [touch locationInView:self];
    self.initialTouchPoint = self.lastTouchPoint;
    
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!CGRectContainsPoint(self.handleView.frame, self.lastTouchPoint)) {
        return;
    }
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint newTouchPoint = [touch locationInView:self];
    
    CGRect newFrame = self.frame;
    newFrame.size.height += newTouchPoint.y - self.lastTouchPoint.y;
    
    CGFloat minHeight = self.handleView.bounds.size.height;
    CGFloat maxHeight = minHeight + self.contentView.bounds.size.height;
    
    if (minHeight <= newFrame.size.height && newFrame.size.height <= maxHeight) {
        self.frame = newFrame;
    }
    
    [self setNeedsDisplay];
    
    self.lastTouchPoint = newTouchPoint;
    
    [super touchesMoved:touches withEvent:event];
}

#define TAP_THRESHOLD 10.0

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint endTouchPoint = [touch locationInView:self];
    
    CGRect openFrame = [self openFrame];
    CGFloat midY = CGRectGetMidY(openFrame);
    
    [UIView beginAnimations:@"WHDrawer" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.2];
    
    CGRect newFrame = self.frame;
    
    BOOL isOpen = [self isOpen];
    BOOL isTap = ABS(self.initialTouchPoint.y - endTouchPoint.y) < TAP_THRESHOLD;
    
    CGSize openSize = openFrame.size;
    CGSize closedSize = self.handleView.bounds.size;
    
    if (isTap) {
        newFrame.size = isOpen ? closedSize : openSize;
    } else if (midY < endTouchPoint.y) {
        newFrame.size = openSize;
    } else {
        newFrame.size = closedSize;
    }
    
    self.frame = newFrame;
    [UIView commitAnimations];
}

@end
