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
#import "COSQLiteStore+Attachments.h"

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"

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
	[db_ setCrashOnErrors: YES];
    [db_ setLogsErrors: YES];
    
	if (![db_ open])
	{
        [self release];
		return nil;
	}
    
    // Use write-ahead-log mode
    {
        NSString *result = [db_ stringForQuery: @"PRAGMA journal_mode=WAL"];
        
        if ([@"wal" isEqualToString: result])
        {
            // The default setting is synchronous=FULL, but according to:
            // http://www.sqlite.org/pragma.html#pragma_synchronous
            // NORMAL is just as safe w.r.t. consistency. FULL only guarantees that the commits
            // will block until data is safely on disk, which we don't need.
            [db_ executeUpdate: @"PRAGMA synchronous=NORMAL"];
        }
        else
        {
            NSLog(@"Enabling WAL mode failed.");
        }
    }    
    
    // Set up schema
    
    [db_ beginTransaction];
    
    // Persistent Root and Branch tables
    
    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS persistentroots (root_id INTEGER PRIMARY KEY, "
     "uuid BLOB, backingstore BLOB, currentbranch INTEGER, metadata BLOB, deleted BOOLEAN)"];
    
    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS branches (branch_id INTEGER PRIMARY KEY, "
     "uuid BLOB, proot INTEGER, head_revid INTEGER, tail_revid INTEGER, current_revid INTEGER, metadata BLOB, deleted BOOLEAN)"];

    [db_ executeUpdate: @"CREATE INDEX IF NOT EXISTS persistentroots_uuid_index ON persistentroots(uuid)"];
    [db_ executeUpdate: @"CREATE INDEX IF NOT EXISTS branches_proot_index ON branches(proot)"];

    // FTS indexes & reference caching tables (in theory, could be regenerated - although not supported)
    
    /**
     * In revid of root_id, there was a reference to dest_root_id
     */
    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS proot_refs (root_id INTEGER, revid INTEGER, dest_root_id INTEGER)"];
    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS attachment_refs (root_id INTEGER, revid INTEGER, attachment_hash BLOB)"];    
    
    [db_ executeUpdate: @"CREATE VIRTUAL TABLE IF NOT EXISTS fts USING fts4(content=\"\", text)"]; // implicit column docid
    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS fts_docid_to_revisionid ("
     "docid INTEGER PRIMARY KEY, root_id INTEGER, revid INTEGER)"];
    
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

- (NSNumber *) rootIdForPersistentRootUUID: (COUUID *)aUUID
{
    return [db_ numberForQuery: @"SELECT root_id FROM persistentroots WHERE uuid = ?", [aUUID dataValue]];
}

/** @taskunit Transactions */

- (void) beginTransaction
{
    [db_ beginDeferredTransaction];
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

- (NSArray *) allBackingUUIDs
{
    NSMutableArray *result = [NSMutableArray array];
    FMResultSet *rs = [db_ executeQuery: @"SELECT coalesce(backingstore, uuid) FROM persistentroots"];
    sqlite3_stmt *statement = [[rs statement] statement];
    
    while ([rs next])
    {
        const void *data = sqlite3_column_blob(statement, 0);
        const int dataSize = sqlite3_column_bytes(statement, 0);
      
        assert(dataSize == 16);
        
        COUUID *uuid = [[COUUID alloc] initWithBytes: data];
        [result addObject: uuid];
        [uuid release];
    }
    [rs close];
    return result;
}

- (COUUID *) backingUUIDForPersistentRootUUID: (COUUID *)aUUID
{
    COUUID *backingUUID = [backingStoreUUIDForPersistentRootUUID_ objectForKey: aUUID];
    if (backingUUID == nil)
    {
        // NOTE: NULL indicates that the backing store UUID is the persistent root UUID
        FMResultSet *rs = [db_ executeQuery: @"SELECT backingstore FROM persistentroots WHERE uuid = ?", [aUUID dataValue]];
        if ([rs next])
        {
            NSData *data = [rs dataForColumnIndex: 0];
            if (data == nil)
            {
                // Common case
                backingUUID = aUUID;
            }
            else
            {
                backingUUID = [COUUID UUIDWithData: data];
            }
            [rs close];
        }
        else
        {
            [rs close];
            [NSException raise: NSInvalidArgumentException format: @"persistent root %@ not found", aUUID];
        }
        
        [backingStoreUUIDForPersistentRootUUID_ setObject: backingUUID forKey: aUUID];
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

/**
 * Updates SQL indexes so given a search query containing contents of
 * the items mentioned by modifiedItems, we can get back aRevision.
 *
 * We'll then have to search to see which persistent roots
 * and which branches reference that revision ID, but that should be really fast.
 */
- (void) updateSearchIndexesForItemUUIDs: (NSArray *)modifiedItems
                              inItemTree: (COItemTree *)anItemTree
                  revisionIDBeingWritten: (CORevisionID *)aRevision
{
    if (modifiedItems == nil)
    {
        modifiedItems = [anItemTree itemUUIDs];
    }
    
    [self beginTransactionIfNeeded];
    
    NSNumber *backingId = [self rootIdForPersistentRootUUID: [aRevision backingStoreUUID]];
    
    NSMutableArray *ftsContent = [NSMutableArray array];
    for (COUUID *uuid in modifiedItems)
    {
        COItem *itemToIndex = [anItemTree itemForUUID: uuid];
        NSString *itemFtsContent = [itemToIndex fullTextSearchContent];
        [ftsContent addObject: itemFtsContent];

        // Look for references to other persistent roots.
        for (COUUID *referenced in [itemToIndex allReferencedPersistentRootUUIDs])
        {
            [db_ executeUpdate: @"INSERT INTO proot_refs(root_id, revid, dest_root_id) VALUES(?,?,?)",
                backingId,
                [NSNumber numberWithLongLong: [aRevision revisionIndex]],
                [self rootIdForPersistentRootUUID: referenced]];
        }
        
        // Look for attachments
        for (NSData *attachment in [itemToIndex attachments])
        {
            [db_ executeUpdate: @"INSERT INTO attachment_refs(root_id, revid, attachment_hash) VALUES(?,?,?)",
             backingId,
             [NSNumber numberWithLongLong: [aRevision revisionIndex]],
             attachment];
        }
    }
    NSString *allItemsFtsContent = [ftsContent componentsJoinedByString: @" "];    
    
    [db_ executeUpdate: @"INSERT INTO fts_docid_to_revisionid(root_id, revid) VALUES(?, ?)",
     backingId,
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
    FMResultSet *rs = [db_ executeQuery: @"SELECT uuid, revid FROM "
                       "(SELECT root_id, revid FROM fts_docid_to_revisionid WHERE docid IN (SELECT docid FROM fts WHERE text MATCH ?)) "
                       "INNER JOIN persistentroots USING(root_id)", aQuery];

    while ([rs next])
    {
        CORevisionID *revId = [[CORevisionID alloc] initWithPersistentRootBackingStoreUUID: [COUUID UUIDWithData: [rs dataForColumnIndex: 0]]
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
                   revisionIDBeingWritten: revidObject];
    
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
        [result addObject: [COUUID UUIDWithData: [rs dataForColumnIndex: 0]]];
    }
    [rs close];
    return result;
}

- (COPersistentRootState *) persistentRootWithUUID: (COUUID *)aUUID
{
    COUUID *currBranch = nil;
    COUUID *backingUUID = nil;
    id meta = nil;
    
    [db_ beginTransaction]; // N.B. The transaction is so the two SELECTs see the same DB. Needed?
    
    NSNumber *root_id = [self rootIdForPersistentRootUUID: aUUID];
    
    {
        FMResultSet *rs = [db_ executeQuery: @"SELECT (SELECT uuid FROM branches WHERE branch_id = currentbranch), coalesce(backingstore, uuid), metadata FROM persistentroots WHERE root_id = ?", root_id];
        if ([rs next])
        {
            currBranch = [COUUID UUIDWithData: [rs dataForColumnIndex: 0]];
            backingUUID = [COUUID UUIDWithData: [rs dataForColumnIndex: 1]];
            meta = [self readMetadata: [rs dataForColumnIndex: 2]];
        }
        else
        {
            [rs close];
            [db_ commit];
            return nil;
        }
        [rs close];
    }
    
    NSMutableDictionary *branchDict = [NSMutableDictionary dictionary];
    
    {
        FMResultSet *rs = [db_ executeQuery: @"SELECT uuid, head_revid, tail_revid, current_revid, metadata, deleted FROM branches WHERE proot = ?",  root_id];
        while ([rs next])
        {
            COUUID *branch = [COUUID UUIDWithData: [rs dataForColumnIndex: 0]];
            CORevisionID *headRevid = [CORevisionID revisionWithBackinStoreUUID: backingUUID
                                                                  revisionIndex: [rs int64ForColumnIndex: 1]];
            CORevisionID *tailRevid = [CORevisionID revisionWithBackinStoreUUID: backingUUID
                                                                  revisionIndex: [rs int64ForColumnIndex: 2]];
            CORevisionID *currentRevid = [CORevisionID revisionWithBackinStoreUUID: backingUUID
                                                                     revisionIndex: [rs int64ForColumnIndex: 3]];
            id branchMeta = [self readMetadata: [rs dataForColumnIndex: 4]];            
            
            COBranchState *state = [[[COBranchState alloc] initWithUUID: branch
                                                        headRevisionId: headRevid
                                                        tailRevisionId: tailRevid
                                                          currentState: currentRevid
                                                               metadata: branchMeta] autorelease];
            state.deleted = [rs boolForColumnIndex: 5];
            
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

- (NSData *) writeMetadata: (NSDictionary *)meta
{
    NSData *data = nil;
    if (meta != nil)
    {
        data = [NSJSONSerialization dataWithJSONObject: meta options: 0 error: NULL];
    }
    return data;
}

- (NSDictionary *) readMetadata: (NSData*)data
{
    if (data != nil)
    {
        return [NSJSONSerialization JSONObjectWithData: data
                                               options: 0
                                                 error: NULL];
    }
    return nil;
}

- (COPersistentRootState *) createPersistentRootWithUUID: (COUUID *)uuid
                                         initialRevision: (CORevisionID *)revId
                                                metadata: (NSDictionary *)metadata
{
    COUUID *branchUUID = [COUUID UUID];

    [self beginTransactionIfNeeded];
    
    [db_ executeUpdate: @"INSERT INTO persistentroots (uuid, "
           "backingstore, currentbranch, metadata, deleted) VALUES(?,?,?,?, 0)",
           [uuid dataValue],
           [uuid isEqual: [revId backingStoreUUID]] ? nil : [[revId backingStoreUUID] dataValue],
           nil,
           [self writeMetadata: metadata]];

    const int64_t root_id = [db_ lastInsertRowId];
    
    [db_ executeUpdate: @"INSERT INTO branches (uuid, proot, head_revid, tail_revid, current_revid, metadata) VALUES(?,?,?,?,?,?)",
           [branchUUID dataValue],
           [NSNumber numberWithLongLong: root_id],
           [NSNumber numberWithLongLong: [revId revisionIndex]],
           [NSNumber numberWithLongLong: [revId revisionIndex]],
           [NSNumber numberWithLongLong: [revId revisionIndex]],
           nil];
    
    const int64_t branch_id = [db_ lastInsertRowId];
    
    [db_ executeUpdate: @"UPDATE persistentroots SET currentbranch = ? WHERE root_id = ?",
      [NSNumber numberWithLongLong: branch_id],
      [NSNumber numberWithLongLong: root_id]];

    [self commitTransactionIfNeeded];
    
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
{
    COUUID *uuid = [COUUID UUID];
    
    CORevisionID *revId = [self writeItemTreeWithNoParent: contents
                                             withMetadata: [NSDictionary dictionary]
                                   inBackingStoreWithUUID: uuid];

    return [self createPersistentRootWithUUID: uuid
                              initialRevision: revId
                                     metadata: metadata];
}


- (COPersistentRootState *) createPersistentRootWithInitialRevision: (CORevisionID *)revId
                                                           metadata: (NSDictionary *)metadata
{
    COUUID *uuid = [COUUID UUID];
    return [self createPersistentRootWithUUID: uuid
                              initialRevision: revId
                                     metadata: metadata];
}

- (BOOL) deletePersistentRoot: (COUUID *)aRoot
{
    NSNumber *root_id = [self rootIdForPersistentRootUUID: aRoot];
    return [db_ executeUpdate: @"UPDATE persistentroots SET deleted = 1 WHERE root_id = ?", root_id];
}

- (BOOL) setCurrentBranch: (COUUID *)aBranch
		forPersistentRoot: (COUUID *)aRoot
{
    NSNumber *root_id = [self rootIdForPersistentRootUUID: aRoot];
    BOOL ok = [db_ executeUpdate: @"UPDATE persistentroots SET currentbranch = (SELECT branch_id FROM branches WHERE proot = ? AND uuid = ?) WHERE root_id = ?",
               root_id,
               root_id,
               [aBranch dataValue]];
   
    return ok;
}

- (COUUID *) createBranchWithInitialRevision: (CORevisionID *)revId
                                  setCurrent: (BOOL)setCurrent
                           forPersistentRoot: (COUUID *)aRoot
{
    [self beginTransactionIfNeeded];
    
    COUUID *branchUUID = [COUUID UUID];
    
    NSNumber *root_id = [self rootIdForPersistentRootUUID: aRoot];
    [db_ executeUpdate: @"INSERT INTO branches (uuid, proot, head_revid, tail_revid, current_revid, metadata, deleted) VALUES(?,?,?,?,?,?,0)",
     [branchUUID dataValue],
     root_id,
     [NSNumber numberWithLongLong: [revId revisionIndex]],
     [NSNumber numberWithLongLong: [revId revisionIndex]],
     [NSNumber numberWithLongLong: [revId revisionIndex]],
     nil];    
    
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
                updateHead: (BOOL)updateHead
{
    if (updateHead)
    {
        return [db_ executeUpdate: @"UPDATE branches SET current_revid = ?, head_revid = ? WHERE uuid = ?",
                [NSNumber numberWithLongLong: [aVersion revisionIndex]],
                [NSNumber numberWithLongLong: [aVersion revisionIndex]],
                [aBranch dataValue]];
        
    }
    else
    {
        return [db_ executeUpdate: @"UPDATE branches SET current_revid = ? WHERE uuid = ?",
                [NSNumber numberWithLongLong: [aVersion revisionIndex]],
                [aBranch dataValue]];
    }
}

- (BOOL) deleteBranch: (COUUID *)aBranch
     ofPersistentRoot: (COUUID *)aRoot
{
    BOOL ok = [db_ executeUpdate: @"UPDATE branches SET deleted = 1 WHERE uuid = ?",
               [aBranch dataValue]];
    
    return ok;
}

- (BOOL) undeleteBranch: (COUUID *)aBranch
       ofPersistentRoot: (COUUID *)aRoot
{
    BOOL ok = [db_ executeUpdate: @"UPDATE branches SET deleted = 0 WHERE uuid = ?",
               [aBranch dataValue]];
    
    return ok;
}

- (BOOL) setMetadata: (NSDictionary *)meta
           forBranch: (COUUID *)aBranch
    ofPersistentRoot: (COUUID *)aRoot
{
    NSNumber *root_id = [self rootIdForPersistentRootUUID: aRoot];
    NSData *data = [self writeMetadata: meta];    
    BOOL ok = [db_ executeUpdate: @"UPDATE branches SET metadata = ? WHERE uuid = ?",
               data,
               [aBranch dataValue]];
    
    return ok;
}

- (BOOL) setMetadata: (NSDictionary *)meta
   forPersistentRoot: (COUUID *)aRoot
{
    NSNumber *root_id = [self rootIdForPersistentRootUUID: aRoot];
    NSData *data = [self writeMetadata: meta];
    BOOL ok = [db_ executeUpdate: @"UPDATE persistentroots SET metadata = ? WHERE root_id = ?",
               data,
               root_id];
    
    return ok;
}


// How to deal with finalizing unreferenced attachments that aren't associated with any persistent root?

- (BOOL) finalizeGarbageAttachments
{
    NSMutableSet *garbage = [NSMutableSet setWithArray: [self attachments]];
    
    FMResultSet *rs = [db_ executeQuery: @"SELECT attachment_hash FROM attachment_refs"];
    while ([rs next])
    {
        [garbage removeObject: [rs dataForColumnIndex: 0]];
    }
    [rs close];

    for (NSData *hash in garbage)
    {
        if (![self deleteAttachment: hash])
        {
            return NO;
        }
    }
    return YES;
}

- (BOOL) finalizeDeletionsForPersistentRoot: (COUUID *)aRoot
{
    COUUID *backingUUID = [self backingUUIDForPersistentRootUUID: aRoot];
    COSQLiteStorePersistentRootBackingStore *backing = [self backingStoreForUUID: backingUUID];
    NSNumber *backingId = [self rootIdForPersistentRootUUID: backingUUID];
    NSData *backingUUIDData = [backingUUID dataValue];
    
    [db_ beginTransaction];
    
    // Delete branches / the persistent root
    
    [db_ executeUpdate: @"DELETE FROM branches WHERE proot IN (SELECT root_id FROM persistentroots WHERE deleted = 1 AND coalesce(backingstore, uuid) = ?)", backingUUIDData];
    [db_ executeUpdate: @"DELETE FROM branches WHERE deleted = 1 AND proot IN (SELECT root_id FROM persistentroots WHERE coalesce(backingstore, uuid) = ?)", backingUUIDData];
    [db_ executeUpdate: @"DELETE FROM persistentroots WHERE deleted = 1 AND coalesce(backingstore, uuid) = ?", backingUUIDData];
    
    NSMutableIndexSet *keptRevisions = [NSMutableIndexSet indexSet];
    
    FMResultSet *rs = [db_ executeQuery: @"SELECT "
                                            "branches.head_revid, "
                                            "branches.tail_revid "
                                            "FROM persistentroots "
                                            "INNER JOIN branches ON persistentroots.root_id = branches.proot "
                                            "WHERE coalesce(persistentroots.backingstore, persistentroots.uuid) = ?", backingUUIDData];
    while ([rs next])
    {
        const int64_t head = [rs int64ForColumnIndex: 0];
        const int64_t tail = [rs int64ForColumnIndex: 1];
        
        NSIndexSet *revs = [backing revidsFromRevid: tail toRevid: head];        
        [keptRevisions addIndexes: revs];
    }
    [rs close];
    
    // Now for each index set in deletedRevisionsForBackingStore, subtract the index set
    // in keptRevisionsForBackingStore
    
    NSMutableIndexSet *deletedRevisions = [NSMutableIndexSet indexSet];
    [deletedRevisions addIndexes: [backing revidsUsedRange]];
    [deletedRevisions removeIndexes: keptRevisions];
    
    for (NSUInteger i = [deletedRevisions firstIndex]; i != NSNotFound; i = [deletedRevisions indexGreaterThanIndex: i])
    {
        
        [db_ executeUpdate: @"DELETE FROM attachment_refs WHERE root_id = ? AND revid = ?",
         backingId,
         [NSNumber numberWithLongLong: i]];
        
        // FIXME: FTS, proot_refs
    }
    
    if (![db_ commit])
    {
        return NO;
    }
    
    // Delete the actual revisions
    if (![backing deleteRevids: deletedRevisions])
    {
        return NO;
    }

    return YES;
}

@end
