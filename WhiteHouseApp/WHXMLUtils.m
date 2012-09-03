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
//  WHXMLUtils.m
//  WhiteHouseApp
//
//

#import "WHXMLUtils.h"

#import <libxml/htmltree.h>
#import <libxml/xpath.h>
#import <libxml/sax.h>


////////////////////////////////////////////////////////////////////////////////
void XPathEach(NSString *xpath, xmlXPathContextPtr ctx, void (^iterator)(xmlNodePtr node))
{
    xmlXPathObjectPtr obj = xmlXPathEval((xmlChar *)[xpath UTF8String], ctx);
    if (!xmlXPathNodeSetIsEmpty(obj->nodesetval)) {
        for (int ii = 0; ii < obj->nodesetval->nodeNr; ii++) {
            xmlNodePtr node = obj->nodesetval->nodeTab[ii];
            iterator(node);
        }
    }
    xmlXPathFreeObject(obj);
}


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation WHXMLUtils


////////////////////////////////////////////////////////////////////////////////
+ (NSString *)textFromHTMLString:(NSString *)text xpath:(NSString *)xpath
{
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    
    htmlDocPtr html = htmlReadMemory(data.bytes, data.length, NULL, NULL, 0);
    
    if (html) {
        xmlXPathContextPtr ctx = xmlXPathNewContext((xmlDocPtr)html);
        NSMutableArray *paragraphs = [NSMutableArray array];
        NSCharacterSet *trimChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        
        XPathEach(xpath, ctx, ^(xmlNodePtr node) {
            // extract the node's text
            xmlChar *nodeText = xmlNodeGetContent(node);
            // put in in a string object by copying the actual bytes
            NSString *nodeString = [[NSString alloc] initWithBytes:nodeText length:xmlStrlen(nodeText) encoding:NSUTF8StringEncoding];
            xmlFree(nodeText);
            
            // see if there's any text there
            NSString *trimmedString = [nodeString stringByTrimmingCharactersInSet:trimChars];
            if ([trimmedString length]) {
                [paragraphs addObject:trimmedString];
            }
        });
        
        xmlXPathFreeContext(ctx);
        xmlFreeDoc(html);
        
        return [paragraphs componentsJoinedByString:@"\n\n"];
    }
    
    return nil;
}

@end
