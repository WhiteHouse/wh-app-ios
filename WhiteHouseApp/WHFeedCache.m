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
//  WHFeedCache.m
//  WhiteHouseApp
//
//

#import "WHFeedCache.h"

#import "WHFeed.h"

#define FEED_ITEM_TABLE "feed_items"
#define FAVORITES_TABLE "favorites"
#define SELECT_LIMIT "50"

static WHFeedCache *sharedCache;


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation WHFeedCache


+ (WHFeedCache *)sharedCache
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[self alloc] init];
    });

    return sharedCache;
}


- (id)init
{
    if ((self = [super init])) {
        [self open];
        
        // this queue serves to serialize database access
        _queue = dispatch_queue_create("gov.eop.wh.database", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


- (void) dealloc
{
    sqlite3_close(_db);
}


- (void)doSQL:(NSString *)sql
{
    char *errorMsg;
    sqlite3_exec(_db, [sql UTF8String], NULL, NULL, &errorMsg);
    if (errorMsg != NULL) {
        NSLog(@"Error executing SQL: %s", errorMsg);
    }
    sqlite3_free(errorMsg);
}


- (NSString *)databaseFilePath
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *paths = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL *directoryURL = [paths objectAtIndex:0];
    if (![fileManager fileExistsAtPath:directoryURL.path]) {
        [fileManager createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [[directoryURL URLByAppendingPathComponent:@"feed_cache.sqlite"] path];
}


- (void)open
{
    NSString *path =[self databaseFilePath];
    DebugLog(@"Opening DB at %@", path);
    const char *db_path = [path UTF8String];
    
    DebugLog(@"sqlite3 lib version: %s", sqlite3_libversion());

    if (sqlite3_open(db_path, &_db) != SQLITE_OK)
    {
        [NSException raise:@"Could not open SQLite database" format:@"Reason: %s", sqlite3_errmsg(_db)];
    }
    
    [self doSQL:@"CREATE TABLE IF NOT EXISTS " FEED_ITEM_TABLE " (feed_url TEXT, guid TEXT UNIQUE, pubDate INTEGER, data BLOB);"];
    [self doSQL:@"CREATE INDEX IF NOT EXISTS index_feed_url ON " FEED_ITEM_TABLE " (feed_url);"];
    [self doSQL:@"CREATE INDEX IF NOT EXISTS index_date ON " FEED_ITEM_TABLE " (pubDate DESC);"];
    
    // favorites table
    [self doSQL:@"CREATE TABLE IF NOT EXISTS " FAVORITES_TABLE " (guid TEXT UNIQUE);"];
    [self doSQL:@"CREATE INDEX IF NOT EXISTS index_favorite_guid ON " FAVORITES_TABLE " (guid);"];
}


- (void)saveFavoriteState:(WHFeedItem *)item
{
    sqlite3_stmt *favoriteStmt;
    char *favSql;
    if (item.isFavorited) {
        favSql = "INSERT OR REPLACE INTO " FAVORITES_TABLE " (guid) values (?)";
    } else {
        favSql = "DELETE FROM " FAVORITES_TABLE " WHERE guid = ?";
    }
    sqlite3_prepare(_db, favSql, -1, &favoriteStmt, NULL);
    
    sqlite3_bind_text(favoriteStmt, 1, item.guid.UTF8String, -1, SQLITE_TRANSIENT);
    if (sqlite3_step(favoriteStmt) != SQLITE_DONE) {
        NSLog(@"Error saving feed item: %s", sqlite3_errmsg(_db));
    }
    sqlite3_finalize(favoriteStmt);
}


- (void)internalSaveItem:(WHFeedItem *)item
{
    DebugLog(@"Saving %@ to database", item.guid);
    
    // use a transaction around our two statements
    sqlite3_exec(_db, "BEGIN", NULL, NULL, NULL);
    
    sqlite3_stmt *stmt;
    char *sql = "INSERT OR REPLACE INTO " FEED_ITEM_TABLE " (feed_url, guid, pubDate, data) VALUES (?, ?, ?, ?);";
    sqlite3_prepare_v2(_db, sql, -1, &stmt, NULL);
    
    // bind the URL
    sqlite3_bind_text(stmt, 1, item.feedURL.absoluteString.UTF8String, -1, SQLITE_TRANSIENT);
    // bind the GUID
    sqlite3_bind_text(stmt, 2, item.guid.UTF8String, -1, SQLITE_TRANSIENT);
    
    // bind the date in seconds since 1970
    sqlite3_bind_int64(stmt, 3, [item.pubDate timeIntervalSince1970]);
    
    // bind the data representing the whole feed item object
    NSData *itemData = [NSKeyedArchiver archivedDataWithRootObject:item];
    sqlite3_bind_blob(stmt, 4, itemData.bytes, itemData.length, SQLITE_TRANSIENT);
    
    // step and check results
    if (sqlite3_step(stmt) != SQLITE_DONE) {
        NSLog(@"Error saving feed item: %s", sqlite3_errmsg(_db));
    }
    sqlite3_finalize(stmt);
    
    [self saveFavoriteState:item];
    
    // finally, commit the transaction
    sqlite3_exec(_db, "COMMIT", NULL, NULL, NULL);
}


- (void)saveFeedItem:(WHFeedItem *)item
{
    dispatch_async(_queue, ^{
        [self internalSaveItem:item];
    });
}


+ (NSSet *)feedItemsFromStatement:(sqlite3_stmt *)stmt
{
    NSMutableSet *result = [NSMutableSet setWithCapacity:50];
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        // get the blob data and length
        const void* bytes = sqlite3_column_blob(stmt, 0);
        int numBytes = sqlite3_column_bytes(stmt, 0);
        
        // and then unarchive the feed item from the blob
        NSData *itemData = [NSData dataWithBytes:bytes length:numBytes];
        WHFeedItem *item = [NSKeyedUnarchiver unarchiveObjectWithData:itemData];
        
        [result addObject:item];
    }
    
    return result;
}


- (NSSet *)favoritedItemsForURL:(NSURL *)feedURL
{
    __block NSSet *result;
    dispatch_sync(_queue, ^{
        sqlite3_stmt *stmt;
        char *sql = "SELECT data FROM feed_items JOIN favorites ON feed_items.guid = favorites.guid WHERE feed_url = ?";
        sqlite3_prepare_v2(_db, sql, -1, &stmt, NULL);
        sqlite3_bind_text(stmt, 1, [[feedURL absoluteString] UTF8String], -1, SQLITE_TRANSIENT);
        
        result = [[self class] feedItemsFromStatement:stmt];
        
        sqlite3_finalize(stmt);
    });
    return result;
}


- (NSSet *)cachedItemsForURL:(NSURL *)feedURL
{
    __block NSSet *result;
    dispatch_sync(_queue, ^{
        sqlite3_stmt *stmt;
        char *sql = "SELECT data FROM feed_items WHERE feed_url = ? ORDER BY pubDate DESC LIMIT " SELECT_LIMIT;
        sqlite3_prepare_v2(_db, sql, -1, &stmt, NULL);
        sqlite3_bind_text(stmt, 1, [[feedURL absoluteString] UTF8String], -1, SQLITE_TRANSIENT);
        
        NSTimeInterval sixMonths = 60 * 60 * 24 * 30 * 6;
        NSTimeInterval cutoff = [[NSDate dateWithTimeIntervalSinceNow:-sixMonths] timeIntervalSince1970];
        sqlite3_bind_int(stmt, 2, cutoff);
        
        result = [[self class] feedItemsFromStatement:stmt];
        
        sqlite3_finalize(stmt);
    });
    return result;
}


@end
