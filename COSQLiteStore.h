#import <Foundation/Foundation.h>

@class COUUID;
@class COItem;
@class CORevisionID;
@class CORevision;
@class COItemTree;
@class FMDatabase;
@class COPersistentRootPlist;

@interface COSQLiteStore : NSObject
{
@private
	NSURL *url_;
    FMDatabase *db_;
    
    NSMutableDictionary *backingStores_; // COUUID (backing store UUID => COCQLiteStorePersistentRootBackingStore)
    NSMutableDictionary *backingStoreUUIDForPersistentRootUUID_;
}

- (id)initWithURL: (NSURL*)aURL;
- (NSURL*)URL;

/** @taskunit reading states */

// because these are immutable, no atomicity/locking/concurrency
// concerns exist.

/**
 * Read commit metadata for a given revision ID
 */
- (CORevision *) revisionForID: (CORevisionID *)aToken;

// FIXME: Add a variant which returns a delta (for efficiency in the case when
// we have the parent already in mem)?
- (COItemTree *) itemTreeForRevisionID: (CORevisionID *)aToken;

/** @taskunit writing states */

- (CORevisionID *) writeItemTree: (COItemTree *)anItemTree
                    withMetadata: (NSDictionary *)metadata
            withParentRevisionID: (CORevisionID *)aParent
                   modifiedItems: (NSArray*)modifiedItems; // array of COUUID

/** @taskunit reading persistent roots */

- (NSSet *) persistentRootUUIDs;

// Returns a snapshot of the state of a persistent root.
- (COPersistentRootPlist *) persistentRootWithUUID: (COUUID *)aUUID;


/** @taskunit writing persistent roots */

- (COPersistentRootPlist *) createPersistentRootWithInitialContents: (COItemTree *)contents
                                                           metadata: (NSDictionary *)metadata;

- (COPersistentRootPlist *) createPersistentRootWithInitialRevision: (CORevisionID *)aRevision
                                                           metadata: (NSDictionary *)metadata;

- (BOOL) deletePersistentRoot: (COUUID *)aRoot;

- (BOOL) setCurrentBranch: (COUUID *)aBranch
		forPersistentRoot: (COUUID *)aRoot;

- (COUUID *) createBranchWithInitialRevision: (CORevisionID *)aToken
                                  setCurrent: (BOOL)setCurrent
                           forPersistentRoot: (COUUID *)aRoot;

/**
 * If we care about detecting concurrent changes,
 * just add a fromVersoin: (token) paramater,
 * and within the transaction, fail if the current state is not the
 * fromVersion.
 */
- (BOOL) setCurrentVersion: (CORevisionID*)aVersion
                 forBranch: (COUUID *)aBranch
          ofPersistentRoot: (COUUID *)aRoot;

- (BOOL) setMetadata: (NSDictionary *)metadata
   forPersistentRoot: (COUUID *)aRoot;

@end
