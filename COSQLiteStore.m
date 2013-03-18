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
    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS persistentroots (uuid BLOB PRIMARY KEY,"
     "backingstore BLOB, plist BLOB, gcroot BOOLEAN)"];
    
    // Create search tables. This uses contentless FTS4 which was added in SQLite 3.7.9
    
    [db_ executeUpdate: @"CREATE VIRTUAL TABLE IF NOT EXISTS fts USING fts4(content=\"\", text)"]; // implicit column docid
    [db_ executeUpdate: @"CREATE TABLE IF NOT EXISTS fts_docid_to_revisionid ("
     "docid INTEGER PRIMARY KEY, revid STRING)"]; // FIXME: store revid efficiently! add UUID table!
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

- (NSSet *) allBackingUUIDs
{
    NSMutableSet *result = [NSMutableSet set];
    FMResultSet *rs = [db_ executeQuery: @"SELECT DISTINCT backingstore FROM persistentroots"];
    while ([rs next])
    {
        [result addObject: [COUUID UUIDWithData: [rs dataForColumnIndex: 0]]];
    }
    [rs close];
    return [NSSet setWithSet: result];
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
    
    [db_ beginTransaction];
    [db_ executeUpdate: @"INSERT INTO fts_docid_to_revisionid(revid) VALUES(?)", [aRevision plist]]; // FIXME: Hack
    [db_ executeUpdate: @"INSERT INTO fts(docid, text) VALUES(?,?)",
     [NSNumber numberWithLongLong: [db_ lastInsertRowId]],
     allItemsFtsContent];
    [db_ commit];
    
    //NSLog(@"Index text '%@' at revision id %@", allItemsFtsContent, aRevision);
    
    assert(![db_ hadError]);
}

- (NSArray *) revisionIDsMatchingQuery: (NSString *)aQuery
{
    NSMutableArray *result = [NSMutableArray array];
    FMResultSet *rs = [db_ executeQuery: @"SELECT revid FROM fts_docid_to_revisionid WHERE docid IN (SELECT docid FROM fts WHERE text MATCH ?)", aQuery];
    while ([rs next])
    {
        [result addObject: [CORevisionID revisionIDWithPlist: [rs stringForColumnIndex: 0]]];
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
    
    CORevisionID *revidObject = [[[CORevisionID alloc] initWithPersistentRootBackingStoreUUID: aBacking
                                                                                revisionIndex: revid] autorelease];
    
    [self updateSearchIndexesForItemUUIDs: modifiedItems
                               inItemTree: anItemTree
                               revisionID: revidObject];
    
    return revidObject;
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

- (NSSet *) gcRootUUIDs
{
    NSMutableSet *result = [NSMutableSet set];
    FMResultSet *rs = [db_ executeQuery: @"SELECT uuid FROM persistentroots WHERE gcroot = 1"];
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
    
    if (plistBlob != nil)
    {
        id plist = [NSJSONSerialization JSONObjectWithData: plistBlob
                                                   options: 0
                                                     error: NULL];
        
        return [[[COPersistentRootState alloc] initWithPlist: plist] autorelease];
    }
    else
    {
        NSLog(@"-[%@ %@]: persistent root not found: %@", [self class], NSStringFromSelector(_cmd), aUUID);
        return nil;
    }
}



/** @taskunit writing persistent roots */

- (BOOL) updatePersistentRoot: (COPersistentRootState *)plist
{
    NSData *data = [NSJSONSerialization dataWithJSONObject: [plist plist] options: 0 error: NULL];

    [db_ beginTransaction];
    [db_ executeUpdate: @"UPDATE persistentroots SET plist = ? WHERE uuid = ?", data, [[plist UUID] dataValue]];
    return [db_ commit];
}

- (BOOL) insertPersistentRoot: (COPersistentRootState *)plist
             backingStoreUUID: (COUUID *)aUUID
                     isGCRoot: (BOOL)isGCRoot
{
    NSData *data = [NSJSONSerialization dataWithJSONObject: [plist plist] options: 0 error: NULL];
    
    return [db_ executeUpdate: @"INSERT INTO persistentroots VALUES(?,?,?,?)",
            [[plist UUID] dataValue], [aUUID dataValue], data, [NSNumber numberWithBool: isGCRoot]];
}


- (COPersistentRootState *) createPersistentRootWithInitialContents: (COItemTree *)contents
                                                           metadata: (NSDictionary *)metadata
                                                           isGCRoot: (BOOL)isGCRoot
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
    
    [self insertPersistentRoot: plist backingStoreUUID: uuid isGCRoot: isGCRoot];
    
    return plist;
}

- (COPersistentRootState *) createPersistentRootWithInitialRevision: (CORevisionID *)revId
                                                           metadata: (NSDictionary *)metadata
                                                           isGCRoot: (BOOL)isGCRoot
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
    
    [self insertPersistentRoot: plist backingStoreUUID: [revId backingStoreUUID] isGCRoot: isGCRoot];
    
    return plist;
}

- (BOOL) isPersistentRootGCRoot: (COUUID *)aRoot
{
    FMResultSet *rs = [db_ executeQuery: @"SELECT gcroot FROM persistentroots WHERE uuid = ?", [aRoot dataValue]];
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
    [db_ beginTransaction];
    
    COUUID *backingUUID = [self backingUUIDForPersistentRootUUID: aRoot];
    
    [db_ executeUpdate: @"DELETE FROM persistentroots WHERE uuid = ?", [aRoot dataValue]];
    
    FMResultSet *rs = [db_ executeQuery: @"SELECT COUNT(backingstore) FROM persistentroots WHERE backingstore = ?", [backingUUID dataValue]];
    if (![rs next])
    {
        [self deleteBackingStoreWithUUID: backingUUID];
    }
    [rs close];
    
    [db_ commit];
    
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
    
    NSMutableSet *garbage = [NSMutableSet setWithSet: [self persistentRootUUIDs]];
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
    COPersistentRootState *plist = [self persistentRootWithUUID: aRoot];
    
    [plist setCurrentBranchUUID: aBranch];
    return [self updatePersistentRoot: plist];
}

- (COUUID *) createBranchWithInitialRevision: (CORevisionID *)aToken
                                  setCurrent: (BOOL)setCurrent
                           forPersistentRoot: (COUUID *)aRoot
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
    
    BOOL ok = [self updatePersistentRoot: plist];
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
{
    COPersistentRootState *plist = [self persistentRootWithUUID: aRoot];
    CORevisionID *oldVersion = [[plist branchPlistForUUID: aBranch] currentState];
    
    [[plist branchPlistForUUID: aBranch] setCurrentState: aVersion];
    
    return  [self updatePersistentRoot: plist];
}

- (BOOL) deleteBranch: (COUUID *)aBranch
     ofPersistentRoot: (COUUID *)aRoot
{
    COPersistentRootState *plist = [self persistentRootWithUUID: aRoot];
    COBranchState *branchState = [plist branchPlistForUUID: aBranch];
    
    [plist removeBranchForUUID: aBranch];
    
    return  [self updatePersistentRoot: plist];
}

- (BOOL) setMetadata: (NSDictionary *)metadata
           forBranch: (COUUID *)aBranch
    ofPersistentRoot: (COUUID *)aRoot
{
    COPersistentRootState *plist = [self persistentRootWithUUID: aRoot];
    [[plist branchPlistForUUID: aBranch] setMetadata:metadata];
    
    return [self updatePersistentRoot: plist];
}

- (BOOL) setMetadata: (NSDictionary *)metadata
   forPersistentRoot: (COUUID *)aRoot
{
    COPersistentRootState *plist = [self persistentRootWithUUID: aRoot];
    [plist setMetadata:metadata];
    
    return [self updatePersistentRoot: plist];
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
    
    NSSet *backingStores = [self allBackingUUIDs];
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
