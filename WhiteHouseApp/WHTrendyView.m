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
//  WHTrendyView.m
//  WhiteHouseApp
//
//

#import "WHTrendyView.h"

@implementation WHTrendyView

@synthesize startColor = _startColor;
@synthesize endColor  = _endColor;

- (void)dealloc
{
    if (_noise != NULL) {
        CGImageRelease(_noise);
    }
}

- (CGImageRef)noise
{
    if (_noise == NULL) {
        CGSize size = self.frame.size;
        int bytes = size.width * size.height;
        uint8_t *pixels = malloc(sizeof(uint8_t) * bytes);
        SecRandomCopyBytes(kSecRandomDefault, bytes, pixels);
        CGColorSpaceRef gray = CGColorSpaceCreateDeviceGray();
        CGContextRef ctx = CGBitmapContextCreate(pixels, size.width, size.height, 8, size.width, gray, 0);
        CGImageRef img = CGBitmapContextCreateImage(ctx);
        CGContextRelease(ctx);
        CGColorSpaceRelease(gray);
        free(pixels);
        _noise = img;
    }
    return _noise;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    const void* colorArray[2] = {[self.startColor CGColor], [self.endColor CGColor]};
    CFArrayRef colors = CFArrayCreate(NULL, colorArray, 2, NULL);
    const CGFloat locations[2] = {0.0, 1.0};
    CGGradientRef gradient = CGGradientCreateWithColors(rgb, colors, locations);
    CGContextDrawRadialGradient(c, gradient, self.center, MAX(self.bounds.size.height, self.bounds.size.width), self.center, 0, 0);
    CGGradientRelease(gradient);
    CFRelease(colors);
    CGColorSpaceRelease(rgb);
    
    
    CGContextSetBlendMode(c, kCGBlendModeScreen);
    CGContextSetAlpha(c, 0.02);
    CGContextDrawTiledImage(c, self.frame, [self noise]);
}

@end
