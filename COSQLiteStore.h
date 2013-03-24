#import <Foundation/Foundation.h>

@class COUUID;
@class COItem;
@class CORevisionID;
@class CORevision;
@class COItemTree;
@class FMDatabase;
@class COPersistentRootState;

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

- (COItemTree *) partialItemTreeFromRevisionID: (CORevisionID *)baseRevid
                                  toRevisionID: (CORevisionID *)finalRevid;

- (COItemTree *) itemTreeForRevisionID: (CORevisionID *)aToken;

/** @taskunit writing states */

- (CORevisionID *) writeItemTree: (COItemTree *)anItemTree
                    withMetadata: (NSDictionary *)metadata
            withParentRevisionID: (CORevisionID *)aParent
                   modifiedItems: (NSArray*)modifiedItems; // array of COUUID

/** @taskunit reading persistent roots */

- (NSArray *) persistentRootUUIDs;
- (NSSet *) gcRootUUIDs;

/**
 * @return  a snapshot of the state of a persistent root, or nil if
 *          the persistent root does not exist.
 */
- (COPersistentRootState *) persistentRootWithUUID: (COUUID *)aUUID;


/* Attachments */

- (NSURL *) URLForAttachment: (NSData *)aHash;
- (NSData *) addAttachmentAtURL: (NSURL *)aURL;


/** @taskunit writing persistent roots */

/*

 Handing creation/deletion properly:
 
 Typical use case:
   - user creates a document, types in it a bit.
   - It's a temporary note, so when theyy're done with it, they delete it.
   - Note is moved to trash. CMD+Z undoes the move to trash.
 
 */
- (COPersistentRootState *) createPersistentRootWithInitialContents: (COItemTree *)contents
                                                           metadata: (NSDictionary *)metadata
                                                           isGCRoot: (BOOL)isGCRoot;

- (COPersistentRootState *) createPersistentRootWithInitialRevision: (CORevisionID *)aRevision
                                                           metadata: (NSDictionary *)metadata
                                                           isGCRoot: (BOOL)isGCRoot;

- (BOOL) deleteGCRoot: (COUUID *)aRoot;


/* Undoable changes */

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

- (BOOL) deleteBranch: (COUUID *)aBranch
     ofPersistentRoot: (COUUID *)aRoot;

- (BOOL) setMetadata: (NSDictionary *)metadata
   forPersistentRoot: (COUUID *)aRoot;

- (BOOL) setMetadata: (NSDictionary *)metadata
           forBranch: (COUUID *)aBranch
    ofPersistentRoot: (COUUID *)aRoot;

/* Search */

- (NSArray *) revisionIDsMatchingQuery: (NSString *)aQuery;

@end
