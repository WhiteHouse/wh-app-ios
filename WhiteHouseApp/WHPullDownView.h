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
//  WHLiveBarView.h
//  WhiteHouseApp
//
//

#import <UIKit/UIKit.h>

/**
 * This pull-down view manages two subviews to present an interface that allows
 * a user to pull down the handle to display content.
 * 
 * The handle view's bounds define the "closed" frame for the view. The union
 * of the handle and content view bounds defines the "open" frame.
 */
@interface WHPullDownView : UIView

- (id)initWithContentView:(UIView *)contentView handleView:(UIView *)handleView;

/**
 * The handle view is what is visible when the drawer is "closed".
 */
@property (nonatomic, strong) UIView *handleView;

/**
 * The content view is displayed when the drawer is "open", and
 * determines the maximum size of the drawer view.
 */
@property (nonatomic, strong) UIView *contentView;

@end
