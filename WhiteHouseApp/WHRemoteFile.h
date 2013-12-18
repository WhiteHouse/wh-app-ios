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
//  WHRemoteFile.h
//  WhiteHouseApp
//
//

typedef BOOL (^ValidatorBlock)(NSData *remoteData);

/**
 * Represents a file backed by a local bundle resource and a remote
 * URL. The file data is loaded from either a cache of the remote 
 * data, or the local bundle. The file is updated asynchronously in
 * the background when -[WHRemoteFile updateWithValidtor:] is called.
 * Any data loaded remotely is only written if the validator returns YES.
 */
@interface WHRemoteFile : NSObject {
    dispatch_queue_t _queue;
}

@property (nonatomic, strong) NSString *bundlePath;
@property (nonatomic, strong) NSURL *remoteURL;

- (id)initWithBundleResource:(NSString *)name ofType:(NSString *)extension remoteURL:(NSURL *)remoteURL;
- (NSData *)data;
- (void)updateWithValidator:(ValidatorBlock)validator;

@end
