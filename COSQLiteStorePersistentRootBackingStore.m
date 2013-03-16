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
    
    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS commits (revid INTEGER PRIMARY KEY ASC, "
                        "contents BLOB, metadata BLOB, parent INTEGER, root BLOB, deltabase INTEGER, "
                        "bytesInDeltaRun INTEGER)"];
    
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
    FMResultSet *rs = [db_ executeQuery: @"SELECT metadata FROM commits WHERE revid = ?", [NSNumber numberWithLongLong: revid]];
	if ([rs next])
	{
        result = [NSJSONSerialization JSONObjectWithData: [rs dataForColumnIndex: 0]
                                                 options: 0
                                                   error: NULL];
	}
    [rs close];
    
	return result;
}

- (int64_t) parentForRevid: (int64_t)revid
{
    int64_t result = -1;
    FMResultSet *rs = [db_ executeQuery: @"SELECT parent FROM commits WHERE revid = ?", [NSNumber numberWithLongLong: revid]];
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
    FMResultSet *rs = [db_ executeQuery: @"SELECT root FROM commits WHERE revid = ?", [NSNumber numberWithLongLong: revid]];
	if ([rs next])
	{
        result = [COUUID UUIDWithData: [rs dataForColumnIndex: 0]];
	}
    [rs close];
    
	return result;
}

- (COPartialItemTree *) partialItemTreeFromRevid: (int64_t)baseRevid toRevid: (int64_t)revid
{
    NSParameterAssert(baseRevid < revid);
    
    NSNumber *revidObj = [NSNumber numberWithLongLong: revid];
    
    NSMutableDictionary *dataForUUID = [NSMutableDictionary dictionary];
    
    FMResultSet *rs = [db_ executeQuery: @"SELECT revid, contents, parent, deltabase "
                                          "FROM commits "
                                          "WHERE revid <= ? AND revid >= (SELECT deltabase FROM commits WHERE revid = ?) "
                                          "ORDER BY revid DESC", revidObj, revidObj];
    int64_t nextRevId = -1;
    
    while ([rs next])
    {
        const int64_t revid = [rs longLongIntForColumnIndex: 0];
        NSData *contentsData = [rs dataForColumnIndex: 1];
        const int64_t parent = [rs longLongIntForColumnIndex: 2];
        const int64_t deltabase = [rs boolForColumnIndex: 3];
        
        if (revid == nextRevId || nextRevId == -1)
        {
            ParseCombinedCommitDataInToUUIDToItemDataDictionary(dataForUUID, contentsData, NO);
            
            if (parent == baseRevid)
            {
                // The caller _already_ has the state of baseRevid. If the state we just processed's
                // parent is baseRevid, we can stop because we have everything already.
                break;
            }
            
            nextRevId = parent;
            
            // validity check            
            assert([rs hasAnotherRow] || deltabase == revid);
        }
        else
        {
            // validity check
            assert([rs hasAnotherRow]);
        }
    }
	
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
    
    COPartialItemTree *result = [[[COPartialItemTree alloc] initWithItemForUUID: resultDict
                                                                   rootItemUUID: root] autorelease];
    return result;
}

- (COItemTree *) itemTreeForRevid: (int64_t)revid
{
    return [[self partialItemTreeFromRevid: -1 toRevid: revid] itemTree];
}

static NSData *contentsBLOBWithItemTree(COItemTree *anItemTree, NSArray *modifiedItems)
{
    NSMutableData *result = [NSMutableData dataWithCapacity: 64536];
    
    for (COUUID *uuid in modifiedItems)
    {
        COItem *item = [anItemTree itemForUUID: uuid];
        NSData *itemJson = [NSJSONSerialization dataWithJSONObject: [item plist] options: 0 error: NULL];
        
        AddCommitUUIDAndDataToCombinedCommitData(result, uuid, itemJson);
    }
    
    return result;
}

- (int64_t) nextRowid
{
    int64_t result = 0;
    FMResultSet *rs = [db_ executeQuery: @"SELECT MAX(rowid) FROM commits"];
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
    
    FMResultSet *rs = [db_ executeQuery: @"SELECT deltabase FROM commits WHERE rowid = ?", [NSNumber numberWithLongLong: aRowid]];
    if ([rs next])
    {
        deltabase = [rs longLongIntForColumnIndex: 0];
    }
    [rs close];

    return deltabase;
}

- (int64_t) bytesInDeltaRunForRowid: (int64_t)aRowid
{
    int64_t bytesInDeltaRun = 0;
    
    FMResultSet *rs = [db_ executeQuery: @"SELECT bytesInDeltaRun FROM commits WHERE rowid = ?", [NSNumber numberWithLongLong: aRowid]];
    if ([rs next])
    {
        bytesInDeltaRun = [rs longLongIntForColumnIndex: 0];
    }
    [rs close];
    
    return bytesInDeltaRun;
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
    const int64_t lastBytesInDeltaRun = [self bytesInDeltaRunForRowid: rowid - 1];
    int64_t deltabase;
    NSData *contentsBlob;
    int64_t bytesInDeltaRun;
    
    // Limit delta runs to 9 commits:
    const BOOL delta = (parent_deltabase != -1 && rowid - parent_deltabase < 100);
    
    // Limit delta runs to 4k
    //const BOOL delta = (parent_deltabase != -1 && lastBytesInDeltaRun < 4096);
    if (delta)
    {
        deltabase = parent_deltabase;
        if (modifiedItems == nil)
        {
            modifiedItems = [anItemTree itemUUIDs];
        }
        contentsBlob = contentsBLOBWithItemTree(anItemTree, modifiedItems);
        bytesInDeltaRun = lastBytesInDeltaRun + [contentsBlob length];
    }
    else
    {
        deltabase = rowid;
        contentsBlob = contentsBLOBWithItemTree(anItemTree, [anItemTree itemUUIDs]);
        bytesInDeltaRun = [contentsBlob length];
    }

    NSData *metadataBlob = nil;
    if (metadata != nil)
    {
        metadataBlob = [NSJSONSerialization dataWithJSONObject: metadata options: 0 error: NULL];
    }
    
    // revid INTEGER PRIMARY KEY | contents BLOB | metadata BLOB | parent INTEGER | root BLOB | deltabase INTEGER | bytesInDeltaRun
    [db_ executeUpdate: @"INSERT INTO commits VALUES (?, ?, ?, ?, ?, ?, ?)",
        [NSNumber numberWithLongLong: rowid],
        contentsBlob,
        metadataBlob,
        [NSNumber numberWithLongLong: aParent],
        [[anItemTree rootItemUUID] dataValue],
        [NSNumber numberWithLongLong: deltabase],
        [NSNumber numberWithLongLong: bytesInDeltaRun]];
    
    [db_ commit];
    
    return rowid;
}

- (void) iteratePartialItemTrees: (void (^)(NSSet *))aBlock
{
    NSMutableDictionary *dataForUUID = [[[NSMutableDictionary alloc] init] autorelease];
    
    FMResultSet *rs = [db_ executeQuery: @"SELECT contents FROM commits"];
    while ([rs next])
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        NSData *contentsData = [rs dataForColumnIndex: 0];
        
        [dataForUUID removeAllObjects];
        ParseCombinedCommitDataInToUUIDToItemDataDictionary(dataForUUID, contentsData, YES);
        
        NSMutableSet *items = [NSMutableSet setWithCapacity: [dataForUUID count]];
        for (COUUID *uuid in dataForUUID)
        {
            id plist = [NSJSONSerialization JSONObjectWithData: [dataForUUID objectForKey: uuid]
                                                       options: 0 error: NULL];
            COItem *item = [[[COItem alloc] initWithPlist: plist] autorelease];
            [items addObject: item];
        }
        aBlock(items);
        
        [pool release];
    }
	
    [rs close];
}

@end
