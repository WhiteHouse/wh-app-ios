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
//  WHRevealViewController.m
//  WhiteHouseApp
//
//

#import "WHRevealViewController.h"

#import <QuartzCore/QuartzCore.h>

@interface WHRevealViewController ()
@property (nonatomic, strong) UIView *contentContainerView;
@property (nonatomic, strong) UIView *contentShieldView;
@end

@implementation WHRevealViewController

@synthesize menuViewController = _menuViewController;
@synthesize contentViewController = _contentViewController;
@synthesize contentContainerView = _contentContainerView;
@synthesize contentShieldView = _contentShieldView;

- (id)initWithMenuViewController:(UIViewController *)menuViewController
           contentViewController:(UIViewController *)contentViewController;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        self.menuViewController = menuViewController;
        self.contentViewController = contentViewController;
    }
    
    return self;
}

- (CGFloat)menuWidth
{
    return 265;
}

- (void)setMenuViewController:(UIViewController *)menuViewController
{
    _menuViewController = menuViewController;
    
    [self addChildViewController:menuViewController];
    
    UIView *menuView = self.menuViewController.view;
    CGRect bounds = self.view.bounds;
    bounds.size.width = [self menuWidth];
    menuView.frame = bounds;
    menuView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    [self.view addSubview:menuView];
    
    [menuViewController didMoveToParentViewController:self];
}

- (void)setContentViewController:(UIViewController *)contentViewController
{
    // get the old view, if any, and remove it
    UIView *oldContentView = self.contentViewController.view;
    [oldContentView removeFromSuperview];
    
    // actually set it
    _contentViewController = contentViewController;
    
    [self addChildViewController:contentViewController];
    
    // this will load the view the first time, triggering viewDidLoad below,
    // loading the menu view first before adding the content view
    if (self.view) {
        UIView *contentView = contentViewController.view;
        contentView.frame = (oldContentView ? oldContentView.frame : self.view.bounds);
        contentView.autoresizingMask = UIViewAutoresizingFlexibleDimensions;
        [self.contentContainerView addSubview:contentView];
    }
    
    [contentViewController didMoveToParentViewController:self];
    
    // the content view should always be in front of the menu
    [self.view bringSubviewToFront:self.contentContainerView];
    // and the shield view should be in front of the content, within the container
    [self.contentContainerView bringSubviewToFront:self.contentShieldView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *container = [[UIView alloc] initWithFrame:self.view.bounds];

    // create the container shadow
    CALayer *layer = container.layer;
    layer.shadowOffset = CGSizeMake(0, 0);
    layer.shadowOpacity = 0.5;
    layer.shadowRadius = 5.0;
    
    // setting the shadow path increases performance considerably
    CGPathRef path = CGPathCreateWithRect(layer.bounds, NULL);
    layer.shadowPath = path;
    CGPathRelease(path);
    
    container.backgroundColor = [UIColor blackColor];
    container.autoresizingMask = UIViewAutoresizingFlexibleDimensions;
    [self.view addSubview:container];
    self.contentContainerView = container;
    
    UIView *shield = [[UIView alloc] initWithFrame:container.bounds];
    shield.autoresizingMask = UIViewAutoresizingFlexibleDimensions;
    
    // dismiss the menu on tap ...
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMenu:)];
    [shield addGestureRecognizer:tap];
    
    // ... and on swipe
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMenu:)];
    swipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [shield addGestureRecognizer:swipe];
    
    // the shield should be hidden by default
    [shield setHidden:YES];
    
    // finally add it to the container
    [container addSubview:shield];
    
    self.contentShieldView = shield;
}

- (void)dismissMenu:(UITapGestureRecognizer *)gesture
{
    [self setMenuVisible:NO wantsFullWidth:NO];
}

- (void)setMenuVisible:(BOOL)menuVisible wantsFullWidth:(BOOL)wantsFullWidth
{
    [UIView beginAnimations:@"ShowMenu" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    CGRect contentFrame = self.contentContainerView.frame;
    CGRect menuFrame = self.menuViewController.view.frame;
    if (menuVisible) {
        // display the shield view to enable dismissing the content view controller
        [self.contentShieldView setHidden:NO];
        
        if (wantsFullWidth) {
            contentFrame.origin.x = self.view.bounds.size.width;
            
            // hide the content view's shadow in full-width mode
            self.contentContainerView.layer.shadowOpacity = 0.0;
            
            // and widen the menu view
            menuFrame.size.width = self.view.bounds.size.width;
        } else {
            contentFrame.origin.x = [self menuWidth];
            // reset the menu width
            menuFrame.size.width = [self menuWidth];
            // reset the shadow
            self.contentContainerView.layer.shadowOpacity = 0.5;
        }
        [self.menuViewController viewWillAppear:YES];
    } else {
        // hide the shield so the user cannot touch it
        [self.contentShieldView setHidden:YES];
        
        contentFrame.origin.x = 0;
        [self.menuViewController viewWillDisappear:YES];
        // reset the menu width
        menuFrame.size.width = [self menuWidth];
    }
    
    self.contentContainerView.frame = contentFrame;
    self.menuViewController.view.frame = menuFrame;

    // hack to get a menu's search bar to animate correctly
    if ([self.menuViewController respondsToSelector:@selector(searchBar)]) {
        [[self.menuViewController performSelector:@selector(searchBar)] layoutSubviews];
    }
    
    [UIView commitAnimations];
}

// Forward the following methods to the child view controllers

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.menuViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.contentViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.menuViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.contentViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.menuViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.contentViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return [self.contentViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

@end
