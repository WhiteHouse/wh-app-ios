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
//  PostTableCell.m
//  


#import "PostTableCell.h"

@implementation PostTableCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    UIColor *blue = [UIColor colorWithRed:0.0 green:0.2 blue:0.4 alpha:1.0];
    if (![self.reuseIdentifier isEqualToString:@"navCell"]){
        if (highlighted) {
            self.card.backgroundColor = blue;
            self.titleLabel.textColor = [UIColor whiteColor];
            self.dateLabel.textColor = [UIColor whiteColor];
        } else {
            self.card.backgroundColor = [UIColor whiteColor];
            self.titleLabel.textColor = [UIColor grayColor];
            self.dateLabel.textColor = [UIColor grayColor];
        }
    }
}

//-(void)layoutSubviews{
//    
//    [super layoutSubviews];
//    if (![NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
//        self.backgroundImage.frame = CGRectMake(12, self.backgroundImage.frame.origin.y, self.frame.size.width-24, self.backgroundImage.frame.size.height);
//        self.card.frame = CGRectMake(12, self.card.frame.origin.y, self.frame.size.width-24, self.card.frame.size.height);
//    }
//    
//}

@end
