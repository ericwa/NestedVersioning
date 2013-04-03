#import "COSQLiteStore.h"
#import "COSQLiteStorePersistentRootBackingStore.h"
#import "CORevisionID.h"
#import "CORevision.h"
#import "COMacros.h"
#import "COUUID.h"
#import "COBranchState.h"
#import "COEdit.h"
#import "COEditCreateBranch.h"
#import "COEditDeleteBranch.h"
#import "COEditSetCurrentBranch.h"
#import "COEditSetCurrentVersionForBranch.h"
#import "COEditSetMetadata.h"
#import "COEditSetBranchMetadata.h"
#import "COItem.h"

#import "FMDatabase.h"

#include <openssl/sha.h>

@implementation COSQLiteStore

- (id)initWithURL: (NSURL*)aURL
{
	SUPERINIT;
    
	url_ = [aURL retain];
	backingStores_ = [[NSMutableDictionary alloc] init];
    backingStoreUUIDForPersistentRootUUID_ = [[NSMutableDictionary alloc] init];
    
	BOOL isDirectory;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: [url_ path]
													   isDirectory: &isDirectory];
	
	if (!exists)
	{
		if (![[NSFileManager defaultManager] createDirectoryAtPath: [url_ path]
                                       withIntermediateDirectories: YES
                                                        attributes: nil
                                                             error: NULL])
		{
			[self release];
			[NSException raise: NSGenericException
						format: @"Error creating store at %@", [url_ path]];
			return nil;
		}
	}
	// assume it is a valid store if it exists... (may not be of course)
	
    db_ = [[FMDatabase alloc] initWithPath: [[url_ path] stringByAppendingPathComponent: @"index.sqlite"]];
    
    [db_ setShouldCacheStatements: YES];
	
	if (![db_ open])
	{
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
    
    [db_ beginTransaction];
    
    // Create search tables. This uses contentless FTS4 which was added in SQLite 3.7.9
    
    [db_ executeUpdate: @"CREATE VIRTUAL TABLE IF NOT EXISTS fts USING fts4(content=\"\", text)"]; // implicit column docid
    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS fts_docid_to_revisionid ("
     "docid INTEGER PRIMARY KEY, backingstore INTEGER, revid INTEGER)"];
    
    // Create persistent root tables
    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS persistentroots (uuid INTEGER PRIMARY KEY, "
     "backingstore INTEGER, gcroot BOOLEAN, currentbranch INTEGER, metadata BLOB)"];

    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS branches (branch INTEGER PRIMARY KEY, "
     "proot INTEGER, head_revid INTEGER, tail_revid INTEGER, current_revid INTEGER, metadata BLOB)"];

    // N.B.: The UNIQUE constraint automatically creates an index on the uuid column,
    // which is used like a normal index to optimise uuid searches. (http://www.sqlite.org/lang_createtable.html)
    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS uuids(uuid_index INTEGER PRIMARY KEY, uuid BLOB UNIQUE)"];
    
    [db_ commit];
    
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
	[url_ release];
    [backingStores_ release];
    [backingStoreUUIDForPersistentRootUUID_ release];
	[super dealloc];
}

- (NSURL*)URL
{
	return url_;
}

/** @taskunit Transactions */

- (void) beginTransaction
{
    [db_ beginTransaction];
    inUserTransaction_ = YES;
}
- (void) commitTransaction
{
    [db_ commit];
    inUserTransaction_ = NO;
}

- (BOOL) beginTransactionIfNeeded
{
    if (!inUserTransaction_)
    {
        return [db_ beginTransaction];
    }
    return YES;
}
- (BOOL) commitTransactionIfNeeded
{
    if (!inUserTransaction_)
    {
        return [db_ commit];
    }
    return YES;
}


/* UUID cache */

// FIXME: Copied & pasted from backing store

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

- (NSNumber *) numberForUUID: (COUUID *)aUUID
{
    return [NSNumber numberWithLongLong: [self keyForUUID: aUUID]];
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

/* */

- (NSArray *) allBackingUUIDs
{
    NSMutableArray *result = [NSMutableArray array];
    FMResultSet *rs = [db_ executeQuery: @"SELECT DISTINCT backingstore FROM persistentroots"];
    while ([rs next])
    {
        [result addObject: [self UUIDForKey: [rs int64ForColumnIndex: 0]]];
    }
    [rs close];
    return result;
}

- (COUUID *) backingUUIDForPersistentRootUUID: (COUUID *)aUUID
{
    COUUID *backingUUID = [backingStoreUUIDForPersistentRootUUID_ objectForKey: aUUID];
    if (backingUUID == nil)
    {        
        FMResultSet *rs = [db_ executeQuery: @"SELECT backingstore FROM persistentroots WHERE uuid = ?", [self numberForUUID: aUUID]];
        if ([rs next])
        {
            backingUUID = [self UUIDForKey: [rs int64ForColumnIndex: 0]];
        }
        [rs close];

        if (backingUUID == nil)
        {
            [NSException raise: NSInvalidArgumentException format: @"persistent root %@ not found", aUUID];
        }
        else
        {
            [backingStoreUUIDForPersistentRootUUID_ setObject: backingUUID forKey: aUUID];
        }
    }
    return backingUUID;
}

- (COSQLiteStorePersistentRootBackingStore *) backingStoreForPersistentRootUUID: (COUUID *)aUUID
{
    return [self backingStoreForUUID:
            [self backingUUIDForPersistentRootUUID: aUUID]];
}

- (NSString *) backingStorePathForUUID: (COUUID *)aUUID
{
    return [[url_ path] stringByAppendingPathComponent: [aUUID stringValue]];
}

- (COSQLiteStorePersistentRootBackingStore *) backingStoreForUUID: (COUUID *)aUUID
{
    COSQLiteStorePersistentRootBackingStore *result = [backingStores_ objectForKey: aUUID];
    if (result == nil)
    {
        result = [[COSQLiteStorePersistentRootBackingStore alloc] initWithPath:
                    [self backingStorePathForUUID: aUUID]];
        [backingStores_ setObject: result forKey: aUUID];
        [result release];
    }
    return result;
}

- (COSQLiteStorePersistentRootBackingStore *) backingStoreForRevisionID: (CORevisionID *)aToken
{
    return [self backingStoreForUUID: [aToken backingStoreUUID]];
}

- (void) deleteBackingStoreWithUUID: (COUUID *)aUUID
{
    {
        COSQLiteStorePersistentRootBackingStore *backing = [backingStores_ objectForKey: aUUID];
        if (backing != nil)
        {
            [backing close];
            [backingStores_ removeObjectForKey: aUUID];
        }
    }
    
    assert([[NSFileManager defaultManager] removeItemAtPath:
            [self backingStorePathForUUID: aUUID] error: NULL]);
}

/** @taskunit reading states */

- (CORevision *) revisionForID: (CORevisionID *)aToken
{
    COSQLiteStorePersistentRootBackingStore *backing = [self backingStoreForRevisionID: aToken];
    
    const int64_t parent = [backing parentForRevid: [aToken revisionIndex]];
    NSDictionary *metadata = [backing metadataForRevid: [aToken revisionIndex]];
    
    CORevision *result = [[[CORevision alloc] initWithRevisionID: aToken
                                                parentRevisionID: [aToken revisionIDWithRevisionIndex: parent]
                                                        metadata: metadata] autorelease];
    
    return result;
}

- (COItemTree *) partialItemTreeFromRevisionID: (CORevisionID *)baseRevid
                                  toRevisionID: (CORevisionID *)finalRevid
{
    NSParameterAssert(baseRevid != nil);
    NSParameterAssert(finalRevid != nil);
    NSParameterAssert([[baseRevid backingStoreUUID] isEqual: [finalRevid backingStoreUUID]]);
    
    COSQLiteStorePersistentRootBackingStore *backing = [self backingStoreForRevisionID: baseRevid];
    COItemTree *result = [backing partialItemTreeFromRevid: [baseRevid revisionIndex]
                                                   toRevid: [finalRevid revisionIndex]];
    return result;
}

- (COItemTree *) itemTreeForRevisionID: (CORevisionID *)aToken
{
    NSParameterAssert(aToken != nil);
    COSQLiteStorePersistentRootBackingStore *backing = [self backingStoreForRevisionID: aToken];
    COItemTree *result = [backing itemTreeForRevid: [aToken revisionIndex]];
    return result;
}

/** @taskunit writing states */

- (BOOL) createBackingStoreWithUUID: (COUUID *)aUUID
{
    return [[NSFileManager defaultManager] createDirectoryAtPath: [[url_ path] stringByAppendingPathComponent: [aUUID stringValue]]
                                     withIntermediateDirectories: NO
                                                      attributes: nil
                                                           error: NULL];
}

/**
 * Updates SQL indexes so given a search query containing contents of
 * the items mentioned by modifiedItems, we can get back aRevision.
 *
 * We'll then have to search to see which persistent roots
 * and which branches reference that revision ID, but that should be really fast.
 */
- (void) updateSearchIndexesForItemUUIDs: (NSArray *)modifiedItems
                              inItemTree: (COItemTree *)anItemTree
                              revisionID: (CORevisionID *)aRevision
{
    if (modifiedItems == nil)
    {
        modifiedItems = [anItemTree itemUUIDs];
    }
    
    NSMutableArray *ftsContent = [NSMutableArray array];
    for (COUUID *uuid in modifiedItems)
    {
        COItem *itemToIndex = [anItemTree itemForUUID: uuid];
        NSString *itemFtsContent = [itemToIndex fullTextSearchContent];
        [ftsContent addObject: itemFtsContent];
    }
    NSString *allItemsFtsContent = [ftsContent componentsJoinedByString: @" "];    
    
    [self beginTransactionIfNeeded];
    [db_ executeUpdate: @"INSERT INTO fts_docid_to_revisionid(backingstore, revid) VALUES(?,?)",
      [NSNumber numberWithLongLong: [self keyForUUID: [aRevision backingStoreUUID]]],
      [NSNumber numberWithLongLong: [aRevision revisionIndex]]];
    [db_ executeUpdate: @"INSERT INTO fts(docid, text) VALUES(?,?)",
     [NSNumber numberWithLongLong: [db_ lastInsertRowId]],
     allItemsFtsContent];
    [self commitTransactionIfNeeded];
    
    //NSLog(@"Index text '%@' at revision id %@", allItemsFtsContent, aRevision);
    
    assert(![db_ hadError]);
}

- (NSArray *) revisionIDsMatchingQuery: (NSString *)aQuery
{
    NSMutableArray *result = [NSMutableArray array];
    FMResultSet *rs = [db_ executeQuery: @"SELECT backingstore, revid FROM fts_docid_to_revisionid WHERE docid IN (SELECT docid FROM fts WHERE text MATCH ?)", aQuery];
    while ([rs next])
    {
        CORevisionID *revId = [[CORevisionID alloc] initWithPersistentRootBackingStoreUUID: [self UUIDForKey: [rs int64ForColumnIndex: 0]]
                                                                             revisionIndex: [rs int64ForColumnIndex: 1]];
        [result addObject: revId];
        [revId release];
    }
    [rs close];
    return result;
}

- (CORevisionID *) writeItemTree: (COItemTree *)anItemTree
                    withMetadata: (NSDictionary *)metadata
            withParentRevisionID: (CORevisionID *)aParent
                   modifiedItems: (NSArray*)modifiedItems // array of COUUID
{
    NSParameterAssert(anItemTree != nil);
    NSParameterAssert(aParent != nil);
    
    return [self writeItemTree: anItemTree
                  withMetadata: metadata
               withParentRevid: [aParent revisionIndex]
        inBackingStoreWithUUID: [aParent backingStoreUUID]
                 modifiedItems: modifiedItems];
}

- (CORevisionID *) writeItemTreeWithNoParent: (COItemTree *)anItemTree
                                withMetadata: (NSDictionary *)metadata
                      inBackingStoreWithUUID: (COUUID *)aBacking
{
    return [self writeItemTree: anItemTree
                  withMetadata: metadata
               withParentRevid: -1
        inBackingStoreWithUUID: aBacking
                 modifiedItems: nil];
}


- (CORevisionID *) writeItemTree: (COItemTree *)anItemTree
                    withMetadata: (NSDictionary *)metadata
                 withParentRevid: (int64_t)parentRevid
          inBackingStoreWithUUID: (COUUID *)aBacking
                   modifiedItems: (NSArray*)modifiedItems // array of COUUID
{
    COSQLiteStorePersistentRootBackingStore *backing = [self backingStoreForUUID: aBacking];
    const int64_t revid = [backing writeItemTree: anItemTree
                                    withMetadata: metadata
                                      withParent: parentRevid
                                   modifiedItems: modifiedItems];
    
    assert(revid >= 0);
    CORevisionID *revidObject = [CORevisionID revisionWithBackinStoreUUID: aBacking
                                                            revisionIndex: revid];
    
    [self updateSearchIndexesForItemUUIDs: modifiedItems
                               inItemTree: anItemTree
                               revisionID: revidObject];
    
    return revidObject;
}

/** @taskunit persistent roots */

- (NSArray *) persistentRootUUIDs
{
    NSMutableArray *result = [NSMutableArray array];
    // FIXME: Benchmark vs join
    FMResultSet *rs = [db_ executeQuery: @"SELECT uuid FROM persistentroots"];
    while ([rs next])
    {
        [result addObject: [self UUIDForKey: [rs int64ForColumnIndex: 0]]];
    }
    [rs close];
    return result;
}

- (NSArray *) gcRootUUIDs
{
    NSMutableArray *result = [NSMutableArray array];
    FMResultSet *rs = [db_ executeQuery: @"SELECT uuid FROM persistentroots WHERE gcroot = 1"];
    while ([rs next])
    {
        [result addObject: [self UUIDForKey: [rs int64ForColumnIndex: 0]]];
    }
    [rs close];
    return result;
}

- (COPersistentRootState *) persistentRootWithUUID: (COUUID *)aUUID
{
    COUUID *currBranch = nil;
    COUUID *backingUUID = nil;
    id meta = nil;
    
    [db_ beginTransaction]; // N.B. The transaction is so the two SELECTs see the same DB
    
    {
        FMResultSet *rs = [db_ executeQuery: @"SELECT currentbranch, backingstore, metadata FROM persistentroots WHERE uuid = ?", [self numberForUUID: aUUID]];
        if ([rs next])
        {
            currBranch = [self UUIDForKey: [rs int64ForColumnIndex: 0]];
            backingUUID = [self UUIDForKey: [rs int64ForColumnIndex: 1]];
            meta = [NSJSONSerialization JSONObjectWithData: [rs dataForColumnIndex: 2]
                                                   options: 0
                                                     error: NULL];
        }
        [rs close];
    }
    
    NSMutableDictionary *branchDict = [NSMutableDictionary dictionary];
    
    {
        FMResultSet *rs = [db_ executeQuery: @"SELECT branch, head_revid, tail_revid, current_revid, metadata FROM branches WHERE proot = ?", [self numberForUUID: aUUID]];
        while ([rs next])
        {
            COUUID *branch = [self UUIDForKey: [rs int64ForColumnIndex: 0]];
            CORevisionID *headRevid = [CORevisionID revisionWithBackinStoreUUID: backingUUID
                                                                  revisionIndex: [rs int64ForColumnIndex: 1]];
            CORevisionID *tailRevid = [CORevisionID revisionWithBackinStoreUUID: backingUUID
                                                                  revisionIndex: [rs int64ForColumnIndex: 2]];
            CORevisionID *currentRevid = [CORevisionID revisionWithBackinStoreUUID: backingUUID
                                                                     revisionIndex: [rs int64ForColumnIndex: 3]];
            id branchMeta = [NSJSONSerialization JSONObjectWithData: [rs dataForColumnIndex: 4]
                                                   options: 0
                                                     error: NULL];
            
            COBranchState *state = [[[COBranchState alloc] initWithUUID: branch
                                                        headRevisionId: headRevid
                                                        tailRevisionId: tailRevid
                                                          currentState: currentRevid metadata: branchMeta] autorelease];
            [branchDict setObject: state forKey: branch];
        }
        [rs close];
    }
    
    [db_ commit];

    COPersistentRootState *result = [[[COPersistentRootState alloc] initWithUUID: aUUID
                                                                   branchForUUID: branchDict
                                                               currentBranchUUID: currBranch
                                                                        metadata: meta] autorelease];
    return result;
}



/** @taskunit writing persistent roots */

- (BOOL) insertPersistentRoot: (COUUID *)aUUID
             backingStoreUUID: (COUUID *)aBackingUUID
                     isGCRoot: (BOOL)isGCRoot
                currentBranch: (COUUID *)aBranch
                     metadata: (NSDictionary *)meta

{
    NSData *data = nil;
    if (meta != nil)
    {
        data = [NSJSONSerialization dataWithJSONObject: meta options: 0 error: NULL];
    }
    
    [self beginTransactionIfNeeded];
    
    BOOL ok = [db_ executeUpdate: @"INSERT INTO persistentroots (uuid, "
            "backingstore, gcroot, currentbranch, metadata) VALUES(?,?,?,?,?)",
            [NSNumber numberWithLongLong: [self keyForUUID: aUUID]],
            [NSNumber numberWithLongLong: [self keyForUUID: aBackingUUID]],
            [NSNumber numberWithBool: isGCRoot],
            [NSNumber numberWithLongLong: [self keyForUUID: aBranch]],
            data];
    
    [self commitTransactionIfNeeded];

    return ok;
}

- (BOOL) insertBranch: (COUUID *)aUUID
       persistentRoot: (COUUID *)aRoot
       headRevisionId: (CORevisionID *)headRevid
       tailRevisionId: (CORevisionID *)tailRevid
    currentRevisionId: (CORevisionID *)currentRevid
             metadata: (NSDictionary *)meta

{
    NSData *data = nil;
    if (meta != nil)
    {
        data = [NSJSONSerialization dataWithJSONObject: meta options: 0 error: NULL];
    }
    
     
    [self beginTransactionIfNeeded];
    
    BOOL ok = [db_ executeUpdate: @"INSERT INTO branches (branch, proot, head_revid, tail_revid, current_revid, metadata) VALUES(?,?,?,?,?,?)",
               [NSNumber numberWithLongLong: [self keyForUUID: aUUID]],
               [NSNumber numberWithLongLong: [self keyForUUID: aRoot]],
               [NSNumber numberWithLongLong: [headRevid revisionIndex]],
               [NSNumber numberWithLongLong: [tailRevid revisionIndex]],
               [NSNumber numberWithLongLong: [currentRevid revisionIndex]],
               data];
    
    [self commitTransactionIfNeeded];
    
    return ok;
}


- (COPersistentRootState *) createPersistentRootWithUUID: (COUUID *)uuid
                                         initialRevision: (CORevisionID *)revId
                                                isGCRoot: (BOOL)isGCRoot
                                                metadata: (NSDictionary *)metadata
{
    COUUID *branchUUID = [COUUID UUID];
    
    [self insertBranch: branchUUID
        persistentRoot: uuid
        headRevisionId: revId
        tailRevisionId: revId
     currentRevisionId: revId
              metadata: nil];
    
    [self insertPersistentRoot: uuid
              backingStoreUUID: [revId backingStoreUUID]
                      isGCRoot: isGCRoot
                 currentBranch: branchUUID
                      metadata: metadata];
    
    // Return info
    
    COBranchState *branch = [[[COBranchState alloc] initWithUUID: branchUUID
                                                  headRevisionId: revId
                                                  tailRevisionId: revId
                                                    currentState: revId
                                                        metadata: nil] autorelease];
    
    COPersistentRootState *plist = [[[COPersistentRootState alloc] initWithUUID: uuid
                                                                  branchForUUID: D(branch, branchUUID)
                                                              currentBranchUUID: branchUUID
                                                                       metadata: metadata] autorelease];
    
    return plist;
}

- (COPersistentRootState *) createPersistentRootWithInitialContents: (COItemTree *)contents
                                                           metadata: (NSDictionary *)metadata
                                                           isGCRoot: (BOOL)isGCRoot
{
    COUUID *uuid = [COUUID UUID];
    
    [self createBackingStoreWithUUID: uuid];
    
    CORevisionID *revId = [self writeItemTreeWithNoParent: contents
                                             withMetadata: [NSDictionary dictionary]
                                   inBackingStoreWithUUID: uuid];

    return [self createPersistentRootWithUUID: uuid
                              initialRevision: revId
                                     isGCRoot: isGCRoot
                                     metadata: metadata];
}


- (COPersistentRootState *) createPersistentRootWithInitialRevision: (CORevisionID *)revId
                                                           metadata: (NSDictionary *)metadata
                                                           isGCRoot: (BOOL)isGCRoot
{
    COUUID *uuid = [COUUID UUID];
    return [self createPersistentRootWithUUID: uuid
                              initialRevision: revId
                                     isGCRoot: isGCRoot
                                     metadata: metadata];
}

- (BOOL) isPersistentRootGCRoot: (COUUID *)aRoot
{
    FMResultSet *rs = [db_ executeQuery: @"SELECT gcroot FROM persistentroots WHERE uuid = ?",
                       [NSNumber numberWithLongLong: [self keyForUUID: aRoot]]];
    if (![rs next])
    {
        [rs close];
        [NSException raise: NSInvalidArgumentException format: @"persistent root not found"];
    }
    
    BOOL isGcRoot = [rs boolForColumnIndex: 0];
    [rs close];
    
    return isGcRoot;
}

- (BOOL) deletePersistentRoot: (COUUID *)aRoot
{
    [self beginTransactionIfNeeded];
    
    COUUID *backingUUID = [self backingUUIDForPersistentRootUUID: aRoot];
    
    [db_ executeUpdate: @"DELETE FROM persistentroots WHERE uuid = ?", [NSNumber numberWithLongLong: [self keyForUUID: aRoot]]];
    [db_ executeUpdate: @"DELETE FROM branches WHERE proot = ?", [NSNumber numberWithLongLong: [self keyForUUID: aRoot]]];
    
    FMResultSet *rs = [db_ executeQuery: @"SELECT COUNT(backingstore) FROM persistentroots WHERE backingstore = ?", [NSNumber numberWithLongLong: [self keyForUUID: backingUUID]]];
    if (![rs next])
    {
        [self deleteBackingStoreWithUUID: backingUUID];
    }
    [rs close];
    
    [self commitTransactionIfNeeded];
    
    [backingStoreUUIDForPersistentRootUUID_ removeObjectForKey: aRoot];
    return YES;
}

- (BOOL) deleteGCRoot: (COUUID *)aRoot
{
    if (![self isPersistentRootGCRoot: aRoot])
    {
        [NSException raise: NSInvalidArgumentException format: @"expected GC root"];
    }

    return [self deletePersistentRoot: aRoot];
}

- (NSSet *)allPersistentRootUUIDsReferencedByPersistentRootWithUUID: (COUUID*)aUUID
{
    NSMutableSet *result = [NSMutableSet set];
    
    // NOTE: This is a bit too coarse; it will return all persistent roots referenced
    // from within the backing store.
    COSQLiteStorePersistentRootBackingStore *backingStore = [self backingStoreForPersistentRootUUID: aUUID];    
    [backingStore iteratePartialItemTrees: ^(NSSet *items)
     {
         for (COItem *item in items)
         {
             [result unionSet: [item allReferencedPersistentRootUUIDs]];
         }
     }];
    
    return result;
}

- (void)recursivelyCollectPersistentRootUUIDsReferencedByPersistentRootWithUUID: (COUUID*)aUUID
                                                                             in: (NSMutableSet *)result
{
    for (COUUID *referenced in [self allPersistentRootUUIDsReferencedByPersistentRootWithUUID: aUUID])
    {
        if (![result containsObject: referenced])
        {
            [result addObject: referenced];
            [self recursivelyCollectPersistentRootUUIDsReferencedByPersistentRootWithUUID: referenced
                                                                                       in: result];
        }
    }
}


- (NSSet *)livePersistentRootUUIDs
{
    NSSet *gcRoots = [self gcRootUUIDs];
    NSMutableSet *result = [NSMutableSet setWithSet: gcRoots];
    for (COUUID *gcRoot in gcRoots)
    {
        [self recursivelyCollectPersistentRootUUIDsReferencedByPersistentRootWithUUID: gcRoot
                                                                                   in: result];
    }
    return result;
}

- (void) gcPersistentRoots
{
    // FIXME: Lock store
    
    NSMutableSet *garbage = [NSMutableSet setWithArray: [self persistentRootUUIDs]];
    [garbage minusSet: [self livePersistentRootUUIDs]];
    
    for (COUUID *uuid in garbage)
    {
        [self deletePersistentRoot: uuid];
    }
    
    // FIXME: Unlock store
}

- (BOOL) setCurrentBranch: (COUUID *)aBranch
		forPersistentRoot: (COUUID *)aRoot
{
    [self beginTransactionIfNeeded];
    
    BOOL ok = [db_ executeUpdate: @"UPDATE persistentroots SET currentbranch = ? WHERE uuid = ?",
               [NSNumber numberWithLongLong:[self keyForUUID: aBranch]],
               [NSNumber numberWithLongLong:[self keyForUUID: aRoot]]];
    
    [self commitTransactionIfNeeded];
    
    return ok;
}

- (COUUID *) createBranchWithInitialRevision: (CORevisionID *)aToken
                                  setCurrent: (BOOL)setCurrent
                           forPersistentRoot: (COUUID *)aRoot
{
    [self beginTransactionIfNeeded];
    
    COUUID *branchUUID = [COUUID UUID];
    
    [self insertBranch: branchUUID
        persistentRoot: aRoot
        headRevisionId: aToken
        tailRevisionId: aToken
     currentRevisionId: aToken
              metadata: nil];
    
    if (setCurrent)
    {
        [self setCurrentBranch: branchUUID
             forPersistentRoot: aRoot];
    }
    
    [self commitTransactionIfNeeded];
    
    return branchUUID;
}

/**
 * TODO: If we care about detecting concurrent changes,
 * just add a fromVersoin: (token) paramater,
 * and within the transaction, fail if the current state is not the
 * fromVersion.
 */
- (BOOL) setCurrentVersion: (CORevisionID*)aVersion
                 forBranch: (COUUID *)aBranch
          ofPersistentRoot: (COUUID *)aRoot
{
    [self beginTransactionIfNeeded];
    
    BOOL ok = [db_ executeUpdate: @"UPDATE branches SET current_revid = ? WHERE branch = ?",
               [NSNumber numberWithLongLong: [aVersion revisionIndex]],
               [NSNumber numberWithLongLong: [self keyForUUID: aBranch]]];
    
    [self commitTransactionIfNeeded];
    
    return ok;
}

- (BOOL) deleteBranch: (COUUID *)aBranch
     ofPersistentRoot: (COUUID *)aRoot
{
    [self beginTransactionIfNeeded];
    
    BOOL ok = [db_ executeUpdate: @"REMOVE FROM branches WHERE branch = ?",
               [NSNumber numberWithLongLong:[self keyForUUID: aBranch]]];
    
    [self commitTransactionIfNeeded];
    
    return ok;
}

- (BOOL) setMetadata: (NSDictionary *)meta
           forBranch: (COUUID *)aBranch
    ofPersistentRoot: (COUUID *)aRoot
{
    NSData *data = nil;
    if (meta != nil)
    {
        data = [NSJSONSerialization dataWithJSONObject: meta options: 0 error: NULL];
    }
    
    [self beginTransactionIfNeeded];
    
    BOOL ok = [db_ executeUpdate: @"UPDATE branches SET metadata = ? WHERE branch = ?",
               data,
               [NSNumber numberWithLongLong:[self keyForUUID: aBranch]]];
    
    [self commitTransactionIfNeeded];

    return ok;
}

- (BOOL) setMetadata: (NSDictionary *)meta
   forPersistentRoot: (COUUID *)aRoot
{
    NSData *data = nil;
    if (meta != nil)
    {
        data = [NSJSONSerialization dataWithJSONObject: meta options: 0 error: NULL];
    }
    
    [self beginTransactionIfNeeded];
    
    BOOL ok = [db_ executeUpdate: @"UPDATE persistentroots SET metadata = ? WHERE uuid = ?",
               data,
               [NSNumber numberWithLongLong:[self keyForUUID: aRoot]]];
    
    [self commitTransactionIfNeeded];
    
    return ok;
}

/* Attachments */

static NSData *hashItemAtURL(NSURL *aURL)
{
    SHA_CTX shactx;
    if (1 != SHA1_Init(&shactx))
    {
        return nil;
    }
    
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingFromURL: aURL
                                                           error: NULL];
    
    int fd = [fh fileDescriptor];
    
    unsigned char buf[4096];
    
    while (1)
    {
        ssize_t bytesread = read(fd, buf, sizeof(buf));
        
        if (bytesread == 0)
        {
            [fh closeFile];
            break;
        }
        if (bytesread < 0)
        {
            [fh closeFile];
            return nil;
        }
        if (1 != SHA1_Update(&shactx, buf, bytesread))
        {
            [fh closeFile];
            return nil;
        }
    }
    
    unsigned char digest[SHA_DIGEST_LENGTH];
    if (1 != SHA1_Final(digest, &shactx))
    {
        return nil;
    }
    return [NSData dataWithBytes: digest length: SHA_DIGEST_LENGTH];
}

static NSString *hexString(NSData *aData)
{
    const NSUInteger len = [aData length];
    if (0 == len)
    {
        return @"";
    }
    const unsigned char *bytes = (const unsigned char *)[aData bytes];
    
    NSMutableString *result = [NSMutableString stringWithCapacity: len * 2];    
    for (NSUInteger i = 0; i < len; i++)
    {
        [result appendFormat:@"%02x", (int)bytes[i]];
    }
    return [NSString stringWithString: result];
}

static NSData *dataFromHexString(NSString *hexString)
{
    NSMutableData *result = [NSMutableData dataWithCapacity: [hexString length] / 2];

    NSScanner *scanner = [NSScanner scannerWithString: hexString];
    unsigned int i;
    while ([scanner scanHexInt: &i])
    {
        unsigned char c = i;
        [result appendBytes: &c length: 1];
    }
    return [NSData dataWithData: result];
}

- (NSURL *) attachmentsURL
{
    return [url_ URLByAppendingPathComponent: @"attachments" isDirectory: YES];
}

- (NSURL *) URLForAttachment: (NSData *)aHash
{
    return [[[self attachmentsURL] URLByAppendingPathComponent: hexString(aHash)]
            URLByAppendingPathExtension: @"attachment"];
}

- (NSData *) addAttachmentAtURL: (NSURL *)aURL
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm createDirectoryAtURL: [self attachmentsURL]
      withIntermediateDirectories: NO
                       attributes: nil
                            error: NULL])
    {
        return nil;
    }
    
    // Hash it
    
    NSData *hash = hashItemAtURL(aURL);
    NSURL *attachmentURL = [self URLForAttachment: hash];
    
    if (![fm fileExistsAtPath: [attachmentURL path]])
    {
        if (NO == [fm copyItemAtURL: aURL toURL: attachmentURL error: NULL])
        {
            return nil;
        }
    }
    
    return hash;
}

- (NSSet *) attachments
{
    NSMutableSet *result = [NSMutableSet set];
    NSArray *files = [[NSFileManager defaultManager] directoryContentsAtPath: [[self attachmentsURL] path]];
    for (NSString *file in files)
    {
        NSString *attachmentHexString = [file stringByDeletingLastPathComponent];
        NSData *hash = dataFromHexString(attachmentHexString);
        [result addObject: hash];
    }
    return result;
}

- (NSSet *)allReferencedAttachments
{
    NSMutableSet *result = [NSMutableSet set];
    
    NSArray *backingStores = [self allBackingUUIDs];
    for (COUUID *backingUUID in backingStores)
    {
        COSQLiteStorePersistentRootBackingStore *backingStore = [self backingStoreForUUID: backingUUID];
        
        [backingStore iteratePartialItemTrees: ^(NSSet *items)
        {
            for (COItem *item in items)
            {
                [result unionSet: [item attachments]];
            }
        }];
    }
    
    return result;
}

- (BOOL) deleteAttachment: (NSData *)hash
{
    return [[NSFileManager defaultManager] removeItemAtPath: [[self URLForAttachment: hash] path]
                                                      error: NULL];
}

- (void) gcAttachments
{
    // FIXME: Lock store
    
    NSMutableSet *garbage = [NSMutableSet setWithSet: [self attachments]];
    [garbage minusSet: [self allReferencedAttachments]];
    
    for (NSData *hash in garbage)
    {
        [self deleteAttachment: hash];
    }
    
    // FIXME: Unlock store
}

@end
