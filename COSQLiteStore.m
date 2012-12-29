#import "COSQLiteStore.h"
#import "COSQLiteStorePersistentRootBackingStore.h"
#import "CORevisionID.h"
#import "CORevision.h"
#import "COMacros.h"
#import "COUUID.h"
#import "COPersistentRootState.h"
#import "COBranchState.h"
#import "COEdit.h"
#import "COEditCreateBranch.h"
#import "COEditDeleteBranch.h"
#import "COEditSetCurrentBranch.h"
#import "COEditSetCurrentVersionForBranch.h"
#import "COEditSetMetadata.h"
#import "COEditSetBranchMetadata.h"

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

    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS operations (uuid BLOB,"
     "plist BLOB)"];
    
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

- (NSSet *) persistentRootUUIDs
{
    NSMutableSet *result = [NSMutableSet set];
    FMResultSet *rs = [db_ executeQuery: @"SELECT uuid FROM persistentroots"];
    while ([rs next])
    {
        [result addObject: [COUUID UUIDWithData: [rs dataForColumnIndex: 0]]];
    }
    [rs close];
    return [NSSet setWithSet: result];
}

- (COPersistentRootState *) persistentRootWithUUID: (COUUID *)aUUID
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
    
    return [[[COPersistentRootState alloc] initWithPlist: plist] autorelease];
}



/** @taskunit writing persistent roots */

- (BOOL) updatePersistentRoot: (COPersistentRootState *)plist
                withOperation: (COEdit *)anEdit
{
    NSData *data = [NSJSONSerialization dataWithJSONObject: [plist plist] options: 0 error: NULL];
    NSData *operationData = [NSJSONSerialization dataWithJSONObject: [anEdit plist] options: 0 error: NULL];
    
    [db_ beginTransaction];
    [db_ executeUpdate: @"UPDATE persistentroots SET plist = ? WHERE uuid = ?", data, [[plist UUID] dataValue]];
    [db_ executeUpdate: @"INSERT INTO operations VALUES(?, ?)", [[plist UUID] dataValue], operationData];
    return [db_ commit];
}

- (BOOL) insertPersistentRoot: (COPersistentRootState *)plist backingStoreUUID: (COUUID *)aUUID
{
    NSData *data = [NSJSONSerialization dataWithJSONObject: [plist plist] options: 0 error: NULL];
    
    return [db_ executeUpdate: @"INSERT INTO persistentroots VALUES(?,?,?)", [[plist UUID] dataValue], [aUUID dataValue], data];
}


- (COPersistentRootState *) createPersistentRootWithInitialContents: (COItemTree *)contents
                                                           metadata: (NSDictionary *)metadata
{
    COUUID *uuid = [COUUID UUID];
    COUUID *branchUUID = [COUUID UUID];
    
    [self createBackingStoreWithUUID: uuid];
    
    CORevisionID *revId = [self writeItemTreeWithNoParent: contents
                                             withMetadata: [NSDictionary dictionary]
                                   inBackingStoreWithUUID: uuid];
    
    COBranchState *branch = [[[COBranchState alloc] initWithUUID: branchUUID
                                                  headRevisionId: revId
                                                  tailRevisionId: revId
                                                    currentState: revId
                                                        metadata: nil] autorelease];

    COPersistentRootState *plist = [[[COPersistentRootState alloc] initWithUUID: uuid
                                                                    revisionIDs: A(revId)
                                                                  branchForUUID: D(branch, branchUUID)
                                                              currentBranchUUID: branchUUID
                                                                       metadata: metadata] autorelease];
    
    [self insertPersistentRoot: plist backingStoreUUID: uuid];
    
    return plist;
}

- (COPersistentRootState *) createPersistentRootWithInitialRevision: (CORevisionID *)revId
                                                                 metadata: (NSDictionary *)metadata
{
    COUUID *uuid = [COUUID UUID];
    COUUID *branchUUID = [COUUID UUID];
    
    COBranchState *branch = [[[COBranchState alloc] initWithUUID: branchUUID
                                                  headRevisionId: revId
                                                  tailRevisionId: revId
                                                    currentState: revId
                                                        metadata: nil] autorelease];
    
    COPersistentRootState *plist = [[[COPersistentRootState alloc] initWithUUID: uuid
                                                                    revisionIDs: A(revId)
                                                                  branchForUUID: D(branch, branchUUID)
                                                              currentBranchUUID: branchUUID
                                                                       metadata: metadata] autorelease];
    
    [self insertPersistentRoot: plist backingStoreUUID: [revId backingStoreUUID]];
    
    return plist;
}

- (BOOL) deletePersistentRoot: (COUUID *)aRoot
{
    return [db_ executeUpdate: @"DELETE FROM persistentroots WHERE uuid = ?", [aRoot dataValue]];
    
    // TODO: Delete backing store if unused by any other persistent roots
}

- (BOOL) setCurrentBranch: (COUUID *)aBranch
		forPersistentRoot: (COUUID *)aRoot
        operationMetadata: (NSDictionary*)operationMetadata
{
    COPersistentRootState *plist = [self persistentRootWithUUID: aRoot];
    COUUID *oldUUID = [plist currentBranchUUID];
    
    [plist setCurrentBranchUUID: aBranch];
    
    COEdit *op = [[[COEditSetCurrentBranch alloc] initWithOldBranchUUID: oldUUID
                                                          newBranchUUID: aBranch
                                                                   UUID: aRoot
                                                                   date: [NSDate date]
                                                            displayName: @""] autorelease];
    
    return [self updatePersistentRoot: plist withOperation: op];
}

- (COUUID *) createBranchWithInitialRevision: (CORevisionID *)aToken
                                  setCurrent: (BOOL)setCurrent
                           forPersistentRoot: (COUUID *)aRoot
                           operationMetadata: (NSDictionary*)operationMetadata
{
    COUUID *branchUUID = [COUUID UUID];
    
    COPersistentRootState *plist = [self persistentRootWithUUID: aRoot];
    
    COBranchState *branch = [[[COBranchState alloc] initWithUUID: branchUUID
                                                  headRevisionId: aToken
                                                  tailRevisionId: aToken
                                                    currentState: aToken
                                                        metadata: nil] autorelease];
    [plist setBranchPlist: branch forUUID: branchUUID];
    [plist addRevisionID: aToken];
    
    COUUID *oldCurrent = nil;
    
    if (setCurrent)
    {
        oldCurrent = [plist currentBranchUUID];
        [plist setCurrentBranchUUID: branchUUID];
    }
    
    COEdit *op = [[[COEditCreateBranch alloc] initWithOldBranchUUID:oldCurrent
                                                      newBranchUUID:branchUUID
                                                         setCurrent:setCurrent
                                                           newToken:aToken
                                                               UUID:aRoot
                                                               date: [NSDate date]
                                                        displayName: @""] autorelease];
    
    BOOL ok = [self updatePersistentRoot: plist withOperation: op];
    if (!ok)
    {
        branch = nil;
    }
    
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
         operationMetadata: (NSDictionary*)operationMetadata
{
    COPersistentRootState *plist = [self persistentRootWithUUID: aRoot];
    CORevisionID *oldVersion = [[plist branchPlistForUUID: aBranch] currentState];
    
    [[plist branchPlistForUUID: aBranch] setCurrentState: aVersion];
    
    COEdit *op = [[[COEditSetCurrentVersionForBranch alloc] initWithBranch: aBranch
                                                                  oldToken: oldVersion
                                                                  newToken: aVersion
                                                                      UUID: aRoot
                                                                      date: [NSDate date]
                                                               displayName: @""] autorelease];
    
    return  [self updatePersistentRoot: plist withOperation: op];
}

- (BOOL) deleteBranch: (COUUID *)aBranch
     ofPersistentRoot: (COUUID *)aRoot
    operationMetadata: (NSDictionary*)operationMetadata
{
    COPersistentRootState *plist = [self persistentRootWithUUID: aRoot];
    COBranchState *branchState = [plist branchPlistForUUID: aBranch];
    
    COEdit *op = [[[COEditDeleteBranch alloc] initWithBranchPlist: branchState
                                                             UUID: aRoot
                                                             date: [NSDate date]
                                                               displayName: @""] autorelease];
    
    [plist removeBranchForUUID: aBranch];
    
    return  [self updatePersistentRoot: plist withOperation: op];
}

- (BOOL) setMetadata: (NSDictionary *)metadata
           forBranch: (COUUID *)aBranch
    ofPersistentRoot: (COUUID *)aRoot
   operationMetadata: (NSDictionary*)operationMetadata
{
    COPersistentRootState *plist = [self persistentRootWithUUID: aRoot];
    NSDictionary *oldMeta = [[plist branchPlistForUUID: aBranch] metadata];
    [[plist branchPlistForUUID: aBranch] setMetadata:metadata];
    
    COEdit *op = [[[COEditSetBranchMetadata alloc] initWithOldMetadata: oldMeta
                                                           newMetadata: metadata
                                                                  UUID:aRoot branchUUID: aBranch
                                                                  date: [NSDate date]
                                                           displayName: @""] autorelease];
    return [self updatePersistentRoot: plist withOperation: op];
}

- (BOOL) setMetadata: (NSDictionary *)metadata
   forPersistentRoot: (COUUID *)aRoot
   operationMetadata: (NSDictionary*)operationMetadata
{
    COPersistentRootState *plist = [self persistentRootWithUUID: aRoot];
    NSDictionary *oldMeta = [plist metadata];
    [plist setMetadata:metadata];
    
    COEdit *op = [[[COEditSetMetadata alloc] initWithOldMetadata: oldMeta
                                                     newMetadata: metadata
                                                            UUID: aRoot
                                                            date: [NSDate date]
                                                     displayName: @""] autorelease];
    return [self updatePersistentRoot: plist withOperation: op];
}

/* Operation Log */

- (NSArray *) operationLogForPersistentRoot: (COUUID *)aRoot
{
    NSMutableArray *result = [NSMutableArray array];
    FMResultSet *rs = [db_ executeQuery: @"SELECT plist FROM operations WHERE uuid = ?", [aRoot dataValue]];
    while ([rs next])
    {
        id plist = [NSJSONSerialization JSONObjectWithData: [rs dataForColumnIndex: 0]
                                                   options: 0
                                                     error: NULL];
        [result addObject: [COEdit editWithPlist: plist]];
    }
    [rs close];
    return result;
}


@end
