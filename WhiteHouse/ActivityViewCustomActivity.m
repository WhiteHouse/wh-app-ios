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

#import "ActivityViewCustomActivity.h"
#import "FavoritesViewController.h"
@implementation ActivityViewCustomActivity

- (NSString *)activityType
{
    return @"gov.whitehouse.App";
}

- (NSString *)activityTitle
{
    return _activityTitle;
}

- (UIImage *)activityImage
{
    // Note: These images need to have a transparent background and I recommend these sizes:
    // iPadShare@2x should be 126 px, iPadShare should be 53 px, iPhoneShare@2x should be 100
    // px, and iPhoneShare should be 50 px. I found these sizes to work for what I was making.
    
//    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//    {
//        return [UIImage imageNamed:@"iPadShare.png"];
//    }
//    else
//    {
        return [UIImage imageNamed:@"favorites-60.png"];
//    }
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    NSLog(@"%s", __FUNCTION__);
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    NSLog(@"%s",__FUNCTION__);
}

- (UIViewController *)activityViewController
{
    NSLog(@"%s",__FUNCTION__);
    return nil;
}

- (void)performActivity
{
    // This is where you can do anything you want, and is the whole reason for creating a custom
    // UIActivity
    FavoritesViewController * favoriteController = [[FavoritesViewController alloc] init];
    if ([favoriteController isFavorited:_post]){
        [favoriteController removeFavoritesObject:_post];
    }else{
        _post.type = @"photo";
        [favoriteController addFavoritesObject:_post];
    }
    
    [self activityDidFinish:YES];
}

@end