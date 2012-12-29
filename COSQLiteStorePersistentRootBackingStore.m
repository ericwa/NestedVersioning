#import "COSQLiteStorePersistentRootBackingStore.h"
#import "COMacros.h"
#import "COItemTree.h"
#import "COItem.h"
#import "COUUID.h"
#import "FMDatabase.h"

@implementation COSQLiteStorePersistentRootBackingStore

- (id)initWithPath: (NSString *)aPath
{
	SUPERINIT;
    
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
                        "contents BLOB, metadata BLOB, parent INTEGER, root BLOB, deltabase INTEGER)"];
    
    if ([db_ hadError])
    {
		NSLog(@"Error %d: %@", [db_ lastErrorCode], [db_ lastErrorMessage]);
        [self release];
		return nil;
	}

	return self;
}

- (void)dealloc
{
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

- (COItemTree *) itemTreeForRevid: (int64_t)revid
{
    NSNumber *revidObj = [NSNumber numberWithLongLong: revid];
    
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    
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
            /**
             * NSString (UUID) -> COItem plist
             */
            NSDictionary *contents = [NSJSONSerialization JSONObjectWithData: contentsData options: 0 error: NULL];
            
            for (NSString *key in contents)
            {
                if ([resultDict objectForKey: [COUUID UUIDWithString: key]] == nil)
                {
                    [resultDict setObject: [[[COItem alloc] initWithPlist: [contents objectForKey: key]] autorelease]
                                   forKey: [COUUID UUIDWithString: key]];
                }
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
    
    // FIXME: run a tree search to collect all used object UUID; so we can weed out any unreferenced ones
    // which may be in resultDict (because they were deleted at some point)
    COItemTree *result = [[[COItemTree alloc] initWithItemForUUID: resultDict
                                                             root: root] autorelease];
    return result;
}

static NSData *contentsBLOBWithItemTree(COItemTree *anItemTree, NSArray *modifiedItems)
{
    /**
     * NSString (UUID) -> COItem plist
     */
    NSMutableDictionary *contents = [NSMutableDictionary dictionary];
    
    for (COUUID *uuid in modifiedItems)
    {
        [contents setObject: [[anItemTree itemForUUID: uuid] plist]
                     forKey: [uuid stringValue]];
    }
    
    return [NSJSONSerialization dataWithJSONObject: contents options: 0 error: NULL];
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
    int64_t deltabase;
    NSData *contentsBlob;
    
    const BOOL delta = (parent_deltabase != -1 && rowid - parent_deltabase < 10);
    if (delta)
    {
        deltabase = parent_deltabase;
        if (modifiedItems == nil)
        {
            modifiedItems = [anItemTree objectUUIDs];
        }
        contentsBlob = contentsBLOBWithItemTree(anItemTree, modifiedItems);
    }
    else
    {
        deltabase = rowid;
        contentsBlob = contentsBLOBWithItemTree(anItemTree, [anItemTree objectUUIDs]);
    }    

    NSData *metadataBlob = nil;
    if (metadata != nil)
    {
        metadataBlob = [NSJSONSerialization dataWithJSONObject: metadata options: 0 error: NULL];
    }
    
    // revid INTEGER PRIMARY KEY | contents BLOB | metadata BLOB | parent INTEGER | root BLOB | deltabase INTEGER
    [db_ executeUpdate: @"INSERT INTO commits VALUES (?, ?, ?, ?, ?, ?)",
        [NSNumber numberWithLongLong: rowid],
        contentsBlob,
        metadataBlob,
        [NSNumber numberWithLongLong: aParent],
        [[anItemTree root] dataValue],
        [NSNumber numberWithLongLong: deltabase]];
    
    [db_ commit];
    
    return rowid;
}

@end
