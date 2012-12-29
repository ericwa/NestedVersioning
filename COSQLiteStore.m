#import "COSQLiteStore.h"
#import "COSQLiteStorePersistentRootBackingStore.h"
#import "CORevisionID.h"
#import "CORevision.h"
#import "COMacros.h"
#import "COUUID.h"
#import "COPersistentRootPlist.h"
#import "FMDatabase.h"

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
    
    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS persistentroots (uuid BLOB PRIMARY KEY,"
     "backingstore BLOB, plist BLOB)"];
    
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

- (COUUID *) backingUUIDForPersistentRootUUID: (COUUID *)aUUID
{
    COUUID *backingUUID = [backingStoreUUIDForPersistentRootUUID_ objectForKey: aUUID];
    if (backingUUID == nil)
    {        
        FMResultSet *rs = [db_ executeQuery: @"SELECT backingstore FROM persistentroots WHERE uuid = ?", [aUUID dataValue]];
        if ([rs next])
        {
            backingUUID = [COUUID UUIDWithData: [rs dataForColumnIndex: 0]];
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

- (COSQLiteStorePersistentRootBackingStore *) backingStoreForUUID: (COUUID *)aUUID
{
    COSQLiteStorePersistentRootBackingStore *result = [backingStores_ objectForKey: aUUID];
    if (result == nil)
    {
        NSString *path = [[url_ path] stringByAppendingPathComponent: [aUUID stringValue]];
        result = [[COSQLiteStorePersistentRootBackingStore alloc] initWithPath: path];
        [backingStores_ setObject: result forKey: aUUID];
        [result release];
    }
    return result;
}

- (COSQLiteStorePersistentRootBackingStore *) backingStoreForRevisionID: (CORevisionID *)aToken
{
    return [self backingStoreForUUID: [aToken backingStoreUUID]];
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


- (COItemTree *) objectTreeForRevision: (CORevisionID *)aToken
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

- (CORevisionID *) writeItemTreeWithNoParent: (COItemTree *)anItemTree
                                withMetadata: (NSDictionary *)metadata
                      inBackingStoreWithUUID: (COUUID *)aBacking
{
    COSQLiteStorePersistentRootBackingStore *backing = [self backingStoreForUUID: aBacking];
    
    const int64_t revid = [backing writeItemTree: anItemTree
                                    withMetadata: metadata
                                      withParent: -1
                                   modifiedItems: nil];
    
    return [[[CORevisionID alloc] initWithPersistentRootBackingStoreUUID: aBacking revisionIndex: revid] autorelease];
}


- (CORevisionID *) writeItemTree: (COItemTree *)anItemTree
                    withMetadata: (NSDictionary *)metadata
            withParentRevisionID: (CORevisionID *)aParent
                   modifiedItems: (NSArray*)modifiedItems // array of COUUID
{
    NSParameterAssert(aParent != nil);
    COSQLiteStorePersistentRootBackingStore *backing = [self backingStoreForRevisionID: aParent];
    
    const int64_t revid = [backing writeItemTree: anItemTree
                                    withMetadata: metadata
                                      withParent: [aParent revisionIndex]
                                   modifiedItems: modifiedItems];
    
    return [aParent revisionIDWithRevisionIndex: revid];
}

/** @taskunit persistent roots */

- (NSArray *) allPersistentRootUUIDs
{
    NSMutableArray *result = [NSMutableArray array];
    FMResultSet *rs = [db_ executeQuery: @"SELECT uuid FROM persistentroots"];
    while ([rs next])
    {
        [result addObject: [COUUID UUIDWithData: [rs dataForColumnIndex: 0]]];
    }
    [rs close];
    return [NSArray arrayWithArray: result];
}

- (id <COPersistentRootMetadata>) persistentRootWithUUID: (COUUID *)aUUID
{
    NSData *plistBlob = nil;
    FMResultSet *rs = [db_ executeQuery: @"SELECT plist FROM persistentroots WHERE uuid = ?", [aUUID dataValue]];
    if ([rs next])
    {
        plistBlob = [rs dataForColumnIndex: 0];
    }
    [rs close];
    
    id plist = [NSJSONSerialization JSONObjectWithData: plistBlob
                                               options: 0
                                                 error: NULL];
    
    return [[[COPersistentRootPlist alloc] initWithPlist: plist] autorelease];
}



/** @taskunit writing persistent roots */

- (BOOL) updatePersistentRoot: (COPersistentRootPlist *)plist
{
    NSData *data = [NSJSONSerialization dataWithJSONObject: [plist plist] options: 0 error: NULL];
    
    return [db_ executeUpdate: @"UPDATE persistentroots SET plist = ? WHERE uuid = ?", data, [[plist UUID] dataValue]];
}

- (BOOL) insertPersistentRoot: (COPersistentRootPlist *)plist backingStoreUUID: (COUUID *)aUUID
{
    NSData *data = [NSJSONSerialization dataWithJSONObject: [plist plist] options: 0 error: NULL];
    
    return [db_ executeUpdate: @"INSERT INTO persistentroots VALUES(?,?,?)", [[plist UUID] dataValue], [aUUID dataValue], data];
}


- (id <COPersistentRootMetadata>) createPersistentRootWithInitialContents: (COItemTree *)contents
                                                                 metadata: (NSDictionary *)metadata
{
    COUUID *uuid = [COUUID UUID];
    COUUID *branch = [COUUID UUID];
    
    [self createBackingStoreWithUUID: uuid];
    
    CORevisionID *revId = [self writeItemTreeWithNoParent: contents
                                             withMetadata: [NSDictionary dictionary]
                                   inBackingStoreWithUUID: uuid];

    COPersistentRootPlist *plist = [[COPersistentRootPlist alloc] initWithUUID: uuid
                                                                   revisionIDs: A(revId)
                                                       headRevisionIdForBranch: D(revId, branch)
                                                       tailRevisionIdForBranch: D(revId, branch)
                                                         currentStateForBranch: D(revId, branch)
                                                             metadataForBranch: [NSDictionary dictionary]
                                                                 currentBranch: branch
                                                                      metadata: metadata];
    
    [self insertPersistentRoot: plist backingStoreUUID: uuid];
    
    return plist;
}

- (id <COPersistentRootMetadata>) createPersistentRootWithInitialRevision: (CORevisionID *)revId
                                                                 metadata: (NSDictionary *)metadata
{
    COUUID *uuid = [COUUID UUID];
    COUUID *branch = [COUUID UUID];
    
    COPersistentRootPlist *plist = [[COPersistentRootPlist alloc] initWithUUID: uuid
                                                                   revisionIDs: A(revId)
                                                       headRevisionIdForBranch: D(revId, branch)
                                                       tailRevisionIdForBranch: D(revId, branch)
                                                         currentStateForBranch: D(revId, branch)
                                                             metadataForBranch: [NSDictionary dictionary]
                                                                 currentBranch: branch
                                                                      metadata: metadata];
    
    [self insertPersistentRoot: plist backingStoreUUID: [revId backingStoreUUID]];
    
    return plist;
}

- (BOOL) deletePersistentRoot: (COUUID *)aRoot
{
    return [db_ executeUpdate: @"DELETE FROM persistentroots WHERE uuid = ?", [aRoot dataValue]];
    
    // FIXME: Delete backing store if unused by any other persistent roots
}

- (BOOL) setCurrentBranch: (COUUID *)aBranch
		forPersistentRoot: (COUUID *)aRoot
{
    COPersistentRootPlist *plist = (COPersistentRootPlist *)[self persistentRootWithUUID: aRoot];
    [plist setCurrentBranchUUID: aBranch];
    return [self updatePersistentRoot: plist];
}

- (COUUID *) createBranchWithInitialRevision: (CORevisionID *)aToken
                                  setCurrent: (BOOL)setCurrent
                           forPersistentRoot: (COUUID *)aRoot
{
    COUUID *branch = [COUUID UUID];
    
    COPersistentRootPlist *plist = (COPersistentRootPlist *)[self persistentRootWithUUID: aRoot];
    
    [plist addRevisionID: aToken];
    [plist setCurrentState: aToken forBranch: branch];
    [plist setHeadRevisionId: aToken forBranch: branch];
    [plist setTailRevisionId: aToken forBranch: branch];
    
    if (setCurrent)
    {
        [plist setCurrentBranchUUID: branch];
    }
    
    BOOL ok = [self updatePersistentRoot: plist];
    if (!ok)
    {
        branch = nil;
    }
    
    return branch;
}

/**
 * If we care about detecting concurrent changes,
 * just add a fromVersoin: (token) paramater,
 * and within the transaction, fail if the current state is not the
 * fromVersion.
 */
- (BOOL) setCurrentVersion: (CORevisionID*)aVersion
                 forBranch: (COUUID *)aBranch
          ofPersistentRoot: (COUUID *)aRoot
{
    COPersistentRootPlist *plist = (COPersistentRootPlist *)[self persistentRootWithUUID: aRoot];
    [plist setCurrentState: aVersion forBranch: aBranch];
    return  [self updatePersistentRoot: plist];
}

- (BOOL) setMetadata: (NSDictionary *)metadata
   forPersistentRoot: (COUUID *)aRoot
{
    COPersistentRootPlist *plist = (COPersistentRootPlist *)[self persistentRootWithUUID: aRoot];
    [plist setMetadata:metadata];
    return [self updatePersistentRoot: plist];
}


@end
