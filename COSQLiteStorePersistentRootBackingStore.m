#import "COSQLiteStorePersistentRootBackingStore.h"
#import "COMacros.h"
#import "COItemTree.h"
#import "COItem.h"
#import "COUUID.h"
#import "FMDatabase.h"
#import "COSQLiteStorePersistentRootBackingStoreBinaryFormats.h"

@implementation COSQLiteStorePersistentRootBackingStore

- (id)initWithPath: (NSString *)aPath
{
	SUPERINIT;
    
    path_ = [aPath retain];
	db_ = [[FMDatabase alloc] initWithPath: [aPath stringByAppendingPathComponent: @"revisions.sqlite"]];
    
    // Setup UUID<->Key map tables
    UUIDKeyToUUID_ = NSCreateMapTable(NSIntegerMapKeyCallBacks, NSObjectMapValueCallBacks, 1024);
    UUIDToUUIDKey_ = NSCreateMapTable(NSObjectMapKeyCallBacks, NSIntegerMapValueCallBacks, 1024);
    
    [db_ setCrashOnErrors: YES];
    [db_ setShouldCacheStatements: YES];
	
	if (![db_ open])
	{
        assert(0);
        [self release];
		return nil;
	}
    
    // Use write-ahead-log mode
    {
        FMResultSet *setToWAL = [db_ executeQuery: @"PRAGMA journal_mode=WAL"];
        [setToWAL next];
        if (![@"wal" isEqualToString: [setToWAL stringForColumnIndex: 0]])
        {
            NSLog(@"Enabling WAL mode failed.");
        }
        [setToWAL close];
    }
    
    // Set up schema
    
    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS data (revid INTEGER, itemid INTEGER, data BLOB)"];
    [db_ executeUpdate: @"CREATE INDEX IF NOT EXISTS data_index ON data(revid)"];
    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS revs (revid INTEGER PRIMARY KEY ASC, "
                         "parent INTEGER, root INTEGER, deltabase INTEGER, bytesInDeltaRun INTEGER, metadata BLOB)"];
    
    // N.B.: The UNIQUE constraint automatically creates an index on the uuid column,
    // which is used like a normal index to optimise uuid searches. (http://www.sqlite.org/lang_createtable.html)
    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS uuids(uuid_index INTEGER PRIMARY KEY, uuid  BLOB UNIQUE)"];
    
    if ([db_ hadError])
    {
		NSLog(@"Error %d: %@", [db_ lastErrorCode], [db_ lastErrorMessage]);
        [self release];
		return nil;
	}
    

	return self;
}

- (void)close
{
    [db_ close];
}

- (void)dealloc
{
    [path_ release];
	[db_ release];
	[super dealloc];
}

/* UUID cache */

- (int64_t)keyForUUID: (COUUID*)uuid
{
    BOOL useTransaction = ![db_ inTransaction];
    if (useTransaction)
    {
        [db_ beginTransaction];
    }
    
    NSData *uuidBlob = [uuid dataValue];
    
    int64_t key = -1;
    FMResultSet *rs = [db_ executeQuery:@"SELECT uuid_index FROM uuids WHERE uuid = ?", uuidBlob];
	if ([rs next])
	{
		key = [rs longLongIntForColumnIndex: 0];
		[rs close];
	}
	else
	{
		[rs close];
        [db_ executeUpdate: @"INSERT INTO uuids(uuid) VALUES(?)", uuidBlob];
        key = [db_ lastInsertRowId];
	}
    
    if (useTransaction)
    {
        [db_ commit];
    }
    
    return key;
}

- (COUUID *) UUIDForKey: (int64_t)key
{
    COUUID *result = nil;
    FMResultSet *rs = [db_ executeQuery:@"SELECT uuid FROM uuids WHERE uuid_index = ?", [NSNumber numberWithLongLong: key]];
	if ([rs next])
	{
		result = [COUUID UUIDWithData: [rs dataForColumnIndex: 0]];
		[rs close];
	}
	else
	{
		[rs close];
	}

    return result;
}

/* DB Setup */


/*
 
 commits
 =======
 
 revid INTEGER PRIMARY KEY | contents BLOB | metadata BLOB | parent INTEGER | root BLOB | deltabase INTEGER
 --------------------------+---------------+---------------+----------------+-----------+------------------
 0                         | ???           | ???           | null           | xxxxxxxxx | 0
 1                         | ???           | ???           | 0              | xxxxxxxxx | 0
 2                         | ???           | ???           | 1              | xxxxxxxxx | 2
 3                         | ???           | ???           | 2              | xxxxxxxxx | 2
 4                         | ???           | ???           | 3              | xxxxxxxxx | 2
 5                         | ???           | ???           | 2              | xxxxxxxxx | 2
 6                         | ???           | ???           | 0              | xxxxxxxxx | 6
 
 
 
 suppose we want to reconstruct the delta revision 500000:
 
 SELECT * FROM test WHERE revid <= 500000 AND revid >= (SELECT MAX(revid) FROM test WHERE delta = 0 AND revid < 500000);

 */

- (NSDictionary *) metadataForRevid: (int64_t)revid
{
    NSDictionary *result = nil;
    FMResultSet *rs = [db_ executeQuery: @"SELECT metadata FROM revs WHERE revid = ?", [NSNumber numberWithLongLong: revid]];
	if ([rs next])
	{
        NSData *data = [rs dataForColumnIndex: 0];
        if (data != nil)
        {
            result = [NSJSONSerialization JSONObjectWithData: data
                                                     options: 0
                                                       error: NULL];
        }
	}
    [rs close];
    
	return result;
}

- (int64_t) parentForRevid: (int64_t)revid
{
    int64_t result = -1;
    FMResultSet *rs = [db_ executeQuery: @"SELECT parent FROM revs WHERE revid = ?", [NSNumber numberWithLongLong: revid]];
	if ([rs next])
	{
        result = [rs longLongIntForColumnIndex: 0];
	}
    [rs close];
    
	return result;
}

- (COUUID *) rootUUIDForRevid: (int64_t)revid
{
    COUUID *result = nil;
    FMResultSet *rs = [db_ executeQuery: @"SELECT root FROM revs WHERE revid = ?", [NSNumber numberWithLongLong: revid]];
	if ([rs next])
	{
        result = [self UUIDForKey: [rs longLongIntForColumnIndex: 0]];
	}
    [rs close];
    
	return result;
}

- (COItemTree *) partialItemTreeFromRevid: (int64_t)baseRevid toRevid: (int64_t)revid
{
    NSParameterAssert(baseRevid < revid);
    
    NSNumber *revidObj = [NSNumber numberWithLongLong: revid];
    
    NSMutableDictionary *dataForUUID = [NSMutableDictionary dictionary];
    
    FMResultSet *rs = [db_ executeQuery: @"SELECT revid, itemid, data, parent, deltabase "
                                          "FROM data INNER JOIN revs USING(revid) "
                                          "WHERE revid <= ? AND revid >= (SELECT deltabase FROM revs WHERE revid = ?) "
                                          "ORDER BY revid DESC", revidObj, revidObj];
    BOOL expectNext = NO; // validity check
    int64_t nextRevId = -1;
    int64_t lastUsedRevId = -1;

    while ([rs next])
    {
        const int64_t revid = [rs longLongIntForColumnIndex: 0];

        if (revid == baseRevid)
        {
            // The caller _already_ has the state of baseRevid. If we are about to processe
            // an item from baseRevid, we can stop because we have everything already.
            expectNext = NO; // validity check
            break;
        }
        
        const BOOL foundNextRevid = (revid == nextRevId || nextRevId == -1);
        const BOOL onSameRevid = (revid == lastUsedRevId);
        
        if (foundNextRevid || onSameRevid)
        {
            // Read all of the items in this revision
            
            COUUID *itemUUID = [self UUIDForKey: [rs longLongIntForColumnIndex: 1]];
            const int64_t parent = [rs longLongIntForColumnIndex: 3];
            const int64_t deltabase = [rs longLongIntForColumnIndex: 4];
            
            if (nil == [dataForUUID objectForKey: itemUUID])
            {
                NSData *itemData = [rs dataForColumnIndex: 2];
                [dataForUUID setObject: itemData
                                forKey: itemUUID];
            }
            
            nextRevId = parent;
                        
            expectNext = (deltabase != revid); // validity check
            
            lastUsedRevId = revid;
        }
        else
        {
            expectNext = NO; // validity check
        }        
    }
	
    assert(!expectNext);// validity check
    
    [rs close];
    
    COUUID *root = [self rootUUIDForRevid: revid];
    
    // Convert dataForUUID to a UUID -> COItem mapping.
    // TODO: Eliminate this by giving COItem to be created with a serialized NSData of itself,
    // and lazily deserializing itself.
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    for (COUUID *uuid in dataForUUID)
    {        
        id plist = [NSJSONSerialization JSONObjectWithData: [dataForUUID objectForKey: uuid]
                                                   options: 0 error: NULL];
        COItem *item = [[[COItem alloc] initWithPlist: plist] autorelease];
        [resultDict setObject: item
                       forKey: uuid];
    }
    
    COItemTree *result = [[[COItemTree alloc] initWithItemForUUID: resultDict
                                                                   rootItemUUID: root] autorelease];
    return result;
}

- (void) benchmarkTableWalk
{
//    FMResultSet *rs = [db_ executeQuery: @"SELECT revid, itemid, data, parent, deltabase "
//                       "FROM data INNER JOIN revs USING(revid) "
//                       "ORDER BY revid DESC"];

    FMResultSet *rs = [db_ executeQuery: @"SELECT itemid FROM data"];

    
    NSLog(@"start walk");
    NSDate *start = [NSDate date];
    
    int64_t rows = 0;
    while ([rs next])
    {
        const int64_t revid = [rs longLongIntForColumnIndex: 0];
        rows ++;
    }
    
    [rs close];

    NSLog(@"walking all commits and reading revid took %lld ns", (long long) ([[NSDate date] timeIntervalSinceDate: start] * 1000000000.0));
}


- (COItemTree *) itemTreeForRevid: (int64_t)revid
{
    return [self partialItemTreeFromRevid: -1 toRevid: revid];
}

- (int64_t) nextRowid
{
    int64_t result = 0;
    FMResultSet *rs = [db_ executeQuery: @"SELECT MAX(rowid) FROM revs"];
	if ([rs next])
	{
        if (![rs columnIndexIsNull: 0])
        {
            result = [rs longLongIntForColumnIndex: 0] + 1;
        }
	}
    [rs close];
    
	return result;
}

- (int64_t) deltabaseForRowid: (int64_t)aRowid
{
    int64_t deltabase = -1;
    
    FMResultSet *rs = [db_ executeQuery: @"SELECT deltabase FROM revs WHERE rowid = ?", [NSNumber numberWithLongLong: aRowid]];
    if ([rs next])
    {
        deltabase = [rs longLongIntForColumnIndex: 0];
    }
    [rs close];

    return deltabase;
}

//- (int64_t) bytesInDeltaRunForRowid: (int64_t)aRowid
//{
//    int64_t bytesInDeltaRun = 0;
//    
//    FMResultSet *rs = [db_ executeQuery: @"SELECT bytesInDeltaRun FROM commits WHERE rowid = ?", [NSNumber numberWithLongLong: aRowid]];
//    if ([rs next])
//    {
//        bytesInDeltaRun = [rs longLongIntForColumnIndex: 0];
//    }
//    [rs close];
//    
//    return bytesInDeltaRun;
//}

- (void) writeItems: (NSArray*)modifiedItems
             inTree: (COItemTree *)anItemTree
              revid: (int64_t)aRevid
{
    for (COUUID *uuid in modifiedItems)
    {
        int64_t itemid = [self keyForUUID: uuid];
        COItem *item = [anItemTree itemForUUID: uuid];
        NSData *itemJson = [NSJSONSerialization dataWithJSONObject: [item plist] options: 0 error: NULL];
        [db_ executeUpdate: @"INSERT INTO data(revid, itemid, data) VALUES(?,?,?)",
            [NSNumber numberWithLongLong: aRevid],
            [NSNumber numberWithLongLong: itemid],
            itemJson];
    }
}

/**
 * @param aParent -1 for no parent, otherwise the parent of this commit
 * @param modifiedItems nil for all items in anItemTree, otherwise a subset
 */
- (int64_t) writeItemTree: (COItemTree *)anItemTree
             withMetadata: (NSDictionary *)metadata
               withParent: (int64_t)aParent
            modifiedItems: (NSArray*)modifiedItems
{
    [db_ beginTransaction];
    
    const int64_t parent_deltabase = [self deltabaseForRowid: aParent];
    const int64_t rowid = [self nextRowid];
    //const int64_t lastBytesInDeltaRun = [self bytesInDeltaRunForRowid: rowid - 1];
    int64_t deltabase;
    NSData *contentsBlob;
    int64_t bytesInDeltaRun;
    
    // Limit delta runs to 9 commits:
    const BOOL delta = (parent_deltabase != -1 && rowid - parent_deltabase < 200);
    
    // Limit delta runs to 4k
    //const BOOL delta = (parent_deltabase != -1 && lastBytesInDeltaRun < 4096);
    if (delta)
    {
        deltabase = parent_deltabase;
        if (modifiedItems == nil)
        {
            modifiedItems = [anItemTree itemUUIDs];
        }
        [self writeItems: modifiedItems inTree: anItemTree revid: rowid];
        //bytesInDeltaRun = lastBytesInDeltaRun + [contentsBlob length];
    }
    else
    {
        deltabase = rowid;
        [self writeItems: [anItemTree itemUUIDs] inTree: anItemTree revid: rowid];
        //bytesInDeltaRun = [contentsBlob length];
    }

    NSData *metadataBlob = nil;
    if (metadata != nil)
    {
        metadataBlob = [NSJSONSerialization dataWithJSONObject: metadata options: 0 error: NULL];
    }
    
    // revid INTEGER PRIMARY KEY | contents BLOB | metadata BLOB | parent INTEGER | root BLOB | deltabase INTEGER | bytesInDeltaRun
    [db_ executeUpdate: @"INSERT INTO revs(revid, parent, root, deltabase, bytesInDeltaRun, metadata) "
                         " VALUES (?, ?, ?, ?, ?, ?)",
        [NSNumber numberWithLongLong: rowid],
        [NSNumber numberWithLongLong: aParent],
        [NSNumber numberWithLongLong: [self keyForUUID: [anItemTree rootItemUUID]]],
        [NSNumber numberWithLongLong: deltabase],
        [NSNumber numberWithLongLong: 0],
        metadataBlob];
    
    [db_ commit];
    
    return rowid;
}

- (void) iteratePartialItemTrees: (void (^)(NSSet *))aBlock
{
//    NSMutableDictionary *dataForUUID = [[[NSMutableDictionary alloc] init] autorelease];
//    
//    FMResultSet *rs = [db_ executeQuery: @"SELECT contents FROM commits"];
//    while ([rs next])
//    {
//        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//        
//        NSData *contentsData = [rs dataForColumnIndex: 0];
//        
//        [dataForUUID removeAllObjects];
//        ParseCombinedCommitDataInToUUIDToItemDataDictionary(dataForUUID, contentsData, YES);
//        
//        NSMutableSet *items = [NSMutableSet setWithCapacity: [dataForUUID count]];
//        for (COUUID *uuid in dataForUUID)
//        {
//            id plist = [NSJSONSerialization JSONObjectWithData: [dataForUUID objectForKey: uuid]
//                                                       options: 0 error: NULL];
//            COItem *item = [[[COItem alloc] initWithPlist: plist] autorelease];
//            [items addObject: item];
//        }
//        aBlock(items);
//        
//        [pool release];
//    }
//	
//    [rs close];
}

@end
