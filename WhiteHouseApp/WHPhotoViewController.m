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
//  WHPhotoViewController.m
//  WhiteHouseApp
//
//

#import "WHPhotoViewController.h"

#import "WHCaptionedPhotoView.h"
#import "WHSharingUtilities.h"
#import "WHFeedItem.h"


@interface WHPhotoViewController ()
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) WHSharingUtilities *sharing;
@property (nonatomic, strong) NIImageMemoryCache *imageCache;
@property (nonatomic, strong) NIImageMemoryCache *thumbnailCache;
@end


@implementation WHPhotoViewController


@synthesize feedItems;
@synthesize queue;
@synthesize sharing;
@synthesize imageCache;
@synthesize thumbnailCache;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.sharing = [[WHSharingUtilities alloc] initWithViewController:self];
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 2;
        
        self.imageCache = [[NIImageMemoryCache alloc] initWithCapacity:20];
        self.thumbnailCache = [[NIImageMemoryCache alloc] initWithCapacity:20];
    }
    
    return self;
}


- (void)share:(id)sender
{
    WHFeedItem *item = (self.feedItems)[self.photoAlbumView.centerPageIndex];
    [self.sharing share:item];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share:)];
    self.navigationItem.rightBarButtonItem = shareButton;
    
    self.title = @"Loading";
    self.photoAlbumView.dataSource = self;
    self.photoAlbumView.loadingImage = [UIImage imageNamed:@"photo-loading-image"];
    [self.photoAlbumView reloadData];
    
    if (self.scrubberIsEnabled) {
        self.photoScrubberView.dataSource = self;
        [self.photoScrubberView reloadData];
    }
}


- (NSString *)cacheKeyForPhotoAtIndex:(NSInteger)photoIndex
{
    return [NSString stringWithFormat:@"image%i", photoIndex];
}


- (void)loadPhotoAtIndex:(NSInteger)photoIndex
{
    WHFeedItem *item = (self.feedItems)[photoIndex];
    WHMediaElement *mediaContent = [item bestContentForWidth:[UIScreen mainScreen].bounds.size.width];
    NINetworkRequestOperation *loadOp = [[NINetworkRequestOperation alloc] initWithURL:mediaContent.URL];
    loadOp.tag = photoIndex;
    [loadOp setDidFinishBlock:^(NIOperation *operation) {
        UIImage* image = [UIImage imageWithData:((NINetworkRequestOperation *) operation).data];
        [self.imageCache storeObject:image withName:[self cacheKeyForPhotoAtIndex:photoIndex]];
        [self.photoAlbumView didLoadPhoto:image atIndex:photoIndex photoSize:NIPhotoScrollViewPhotoSizeOriginal];
    }];
    
    [self.queue addOperation:loadOp];
}


- (void)loadThumbnailAtIndex:(NSInteger)photoIndex
{
    WHFeedItem *item = (self.feedItems)[photoIndex];
    
    // get the smallest thumbnail available
    WHMediaElement *mediaContent = [item bestThumbnailForWidth:0];
    NINetworkRequestOperation *loadOp = [[NINetworkRequestOperation alloc] initWithURL:mediaContent.URL];
    loadOp.tag = photoIndex;
    [loadOp setDidFinishBlock:^(NIOperation *operation) {
        UIImage* image = [UIImage imageWithData:((NINetworkRequestOperation *) operation).data];
        [self.imageCache storeObject:image withName:[self cacheKeyForPhotoAtIndex:photoIndex]];
        [self.photoScrubberView didLoadThumbnail:image atIndex:photoIndex];
    }];
    
    [self.queue addOperation:loadOp];
}


- (UIImage *)photoAlbumScrollView:(NIPhotoAlbumScrollView *)photoAlbumScrollView
                     photoAtIndex:(NSInteger)photoIndex
                        photoSize:(NIPhotoScrollViewPhotoSize *)photoSize
                        isLoading:(BOOL *)isLoading
          originalPhotoDimensions:(CGSize *)originalPhotoDimensions
{
    *isLoading = YES;
    [self loadPhotoAtIndex:photoIndex];
    return nil;
}


- (UIView<NIPagingScrollViewPage>*)pagingScrollView:(NIPagingScrollView *)pagingScrollView pageViewForIndex:(NSInteger)pageIndex {
    UIView<NIPagingScrollViewPage>* pageView = nil;
    
    DebugLog(@"loading view for page %i", pageIndex);
    
    static NSString *reuseID = @"PhotoView";
    
    pageView = [pagingScrollView dequeueReusablePageWithIdentifier:reuseID];
    if (nil == pageView) {
        pageView = [[WHCaptionedPhotoView alloc] init];
        pageView.reuseIdentifier = reuseID;
    }
    
    NIPhotoScrollView* photoScrollView = (NIPhotoScrollView *)pageView;
    photoScrollView.photoScrollViewDelegate = self.photoAlbumView;
    photoScrollView.zoomingAboveOriginalSizeIsEnabled = [self.photoAlbumView isZoomingAboveOriginalSizeEnabled];
    
    WHCaptionedPhotoView* captionedView = (WHCaptionedPhotoView *)pageView;
    WHFeedItem *item = [self feedItems][pageIndex];
    [captionedView setCaption:item.descriptionText];
    
    if (self.isChromeHidden) {
        [captionedView setCaptionHidden:YES animated:NO];
    }
    
    return pageView;
}


- (NSInteger)numberOfPagesInPagingScrollView:(NIPagingScrollView *)pagingScrollView
{
    return self.feedItems.count;
}


- (void)photoAlbumScrollView:(NIPhotoAlbumScrollView *)photoAlbumScrollView
     stopLoadingPhotoAtIndex:(NSInteger)photoIndex
{
    for (NIOperation *op in [self.queue operations]) {
        if (op.tag == photoIndex) {
            [op cancel];
        }
    }
}


- (void)willHideChrome:(BOOL)animated
{
    DebugLog(@"number of pages: %i", self.photoAlbumView.visiblePages.count);
    for (WHCaptionedPhotoView *page in self.photoAlbumView.visiblePages) {
        [page setCaptionHidden:YES animated:animated];
    }
}


- (void)didHideChrome
{
    [super didHideChrome];
    
    for (WHCaptionedPhotoView *page in self.photoAlbumView.visiblePages) {
        [page setCaptionHidden:YES animated:NO];
    }
}


- (void)willShowChrome:(BOOL)animated
{
    for (WHCaptionedPhotoView *page in self.photoAlbumView.visiblePages) {
        [page setCaptionHidden:NO animated:animated];
    }
}


#pragma mark Scrubber methods


- (NSInteger)numberOfPhotosInScrubberView:(NIPhotoScrubberView *)photoScrubberView
{
    return self.feedItems.count;
}


- (UIImage *)photoScrubberView:(NIPhotoScrubberView *)photoScrubberView thumbnailAtIndex:(NSInteger)thumbnailIndex
{
    UIImage *image = nil;
    
    // try the full image cache first... unlikely, but we don't want to do redundant work
    image = [self.imageCache objectWithName:[self cacheKeyForPhotoAtIndex:thumbnailIndex]];
    if (image) {
        return image;
    }
    
    // then look at the thumbnail cache
    image = [self.thumbnailCache objectWithName:[self cacheKeyForPhotoAtIndex:thumbnailIndex]];
    if (image) {
        return image;
    }
    
    // otherwise, load it
    [self loadThumbnailAtIndex:thumbnailIndex];
    
    return nil;
}


@end
