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
//  PostCollectionCell.m
//  WhiteHouse
//

#import "PostCollectionCell.h"

@implementation PostCollectionCell

-(void)layoutSubviews{
    
    [super layoutSubviews];

    if([UIScreen mainScreen].scale > 2.9){ // iPhone 6 plus
        if ([self.reuseIdentifier isEqualToString:@"BlogColCellNoImage"]){
            self.dateLabel.frame = CGRectMake(10, 10, self.frame.size.width - 10, self.dateLabel.frame.size.height);
            self.titleLabel.frame = CGRectMake(10, 20, self.frame.size.width -10, 50);
            self.descriptionLabel.frame = CGRectMake(10, 75, self.frame.size.width -20 , self.frame.size.height-75);
        }else{
            self.dateLabel.frame = CGRectMake(self.dateLabel.frame.origin.x, self.frame.size.height - 63, self.frame.size.width - 10, self.dateLabel.frame.size.height);
            self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, self.frame.size.height - 53, self.frame.size.width - 10, self.titleLabel.frame.size.height);
            self.highlightLabel.frame = CGRectMake(0, self.frame.size.height - 68, self.frame.size.width, 68);
            self.backgroundImage.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - self.highlightLabel.frame.size.height);
            self.playImage.frame = CGRectMake(self.frame.size.width / 2 - (self.playImage.frame.size.width/2), self.frame.size.height / 2.0 - (self.playImage.frame.size.height/1.2), self.playImage.frame.size.width, self.playImage.frame.size.height);
        }
    }else{
        if ([self.reuseIdentifier isEqualToString:@"BlogColCellNoImage"]){
            self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, 20, self.frame.size.width -10, self.titleLabel.frame.size.height);
            self.descriptionLabel.frame = CGRectMake(10, 75, self.frame.size.width -20 , self.frame.size.height-75);
        }else{
            self.dateLabel.frame = CGRectMake(self.dateLabel.frame.origin.x, self.frame.size.height - 63, self.frame.size.width - 10, self.dateLabel.frame.size.height);
            self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, self.frame.size.height - 53, self.frame.size.width - 10, self.titleLabel.frame.size.height);
            self.highlightLabel.frame = CGRectMake(0, self.frame.size.height - 68, self.frame.size.width, 68);
            self.backgroundImage.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - self.highlightLabel.frame.size.height);
            self.playImage.frame = CGRectMake(self.frame.size.width / 2 - (self.playImage.frame.size.width/2), self.frame.size.height / 2.0 - (self.playImage.frame.size.height/1.2), self.playImage.frame.size.width, self.playImage.frame.size.height);
        }
    }
    
}

@end
