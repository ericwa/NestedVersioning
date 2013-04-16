#import <Foundation/Foundation.h>

@class COUUID;
@class COItem;
@class CORevisionID;
@class CORevision;
@class COItemTree;
@class FMDatabase;
@class COPersistentRootState;

/**
 * This class implements a Core Object store using SQLite databases.
 *
 * Conceptual model:
 *
 * - A _store_ is comprised of a set of _persistent roots_.
 *   Each _persistent root_ has a UUID and it is unique within the store; however, it is possible for
 *   the same _persistent root_ to be in multiple stores, without necessairily having the same contents.
 *   (Consider cases where a store is copied onto backup storage.)
 *
 *   A _persistent root_ consists of:
 *
 *     - a set of _branches_, and a marker indicating the current branch
 *     - a flexible, user-facing metadata dictionary, for storing thigns like name, author.
 *       This metadata is not interpreted or used by the framework.
 *
 *   A _branch_ consists of a linear sequence of _revisions_, which were produced by making
 *   sequential edits to the _contents_ of the persistent root, as well as a marker indicating the
 *   current revision.
 *
 *   A _revision_ is a snapshot of the persistent root contents. 
 *
 *   The contents of a revision consists of a graph of
 *   _embedded objects_, along with one designated as the _root embedded object_. The designation
 *   of _root embedded object_ is for users' convenience; the intent is that this object is what
 *   the persistent root represents. Note that the root embedded object does not have the same UUID
 *   as the _persistent root_ that contains it.
 *
 *   Core Objects and Branches are mutable, and any changes made are unversioned (only the current
 *   state is stored.) Undo/redo should be implemented at a higher layer by logging changes made
 *   to the store.
 *
 *   The revisions of the versioned contents are stored in a DAG structure. Each revision is
 *   identified by, currently, an opaque ID (internally, backing store UUID + an integer).
 *   A hash, like git and other use, could be used instead - the current scheme was chosen for
 *   simplicity and speculated better performance but we may switch to a hash.
 *
 *
 * Garbage collection / deletion semantics:
 *
 * - Persistent roots are never garbage collected, they must be deleted explicitly by the user.
 *   For convenience, once deleted, they can be undeleted. Typical use case:
 *        - user creates a document, types in it a bit.
 *        - It's a temporary note, so when theyy're done with it, they delete it.
 *        - Note is moved to trash. CMD+Z undoes the move to trash.
 *   So by having the not deleted/deleted flag at the store level, that would let us easily
 *   make "delete" a command-pattern invertible undo action.
 *
 * - There are attachments which are stored separately from the revision data in backing stores,
 *   however from the point of view of data lifetime, it's as if the attachment is part of the revision
 *   data in the backing store.
 *
 * - Branches can be deleted. Like persistent roots, they can be undeleted, and the list of deleted braches
 *   for a persistent root can be queried.  
 *
 * - There is a "finalize deletions" command that the user can invoke, which permanently removes:
 *   * persistent roots marked as deleted
 *   * branches marked as deleted
 *   * unreachable revisions
 *   * unreachable attachments
 *
 * - Additionally, over time, the user may want to prune the history of a branch. This is implemented
 *   by moving ahead the 'base' pointer of a branch, and performing a "finalize deletions".
 * 
 * - Since "finalize deletions" actually deletes data and frees disk space, there are the following
 *   side effects:
 *   * Calling -undeletePersistentRoot: will return NO if "finalize deletions" has been performed
 *     since the persistent root was deleted with -deletePersistentRoot:
 *   * Calling -undeleteBranch: will return NO if "finalize deletions" has been performed
 *     since the branch was deleted with -deleteBranch:
 *   * Calling -setCurrentVersion:... will return NO if the revision has been deleted.
 * 
 * Implementation summary:
 *
 * - COSQLiteStore has one SQLite database which stores the persistent root and branch metadata,
 *   as well as full text indexes and an index of attachment references (for garbage collecting attachments),
 *   and an index of cross-persistent root references (not used for anything internally, but exposed to
 *   users of the class so we can quickly answer questions like "show all references to this persistent root")
 *
 * - Persistent root contents are stored in "backing stores". See COSQLiteStorePersistentRootBackingStore.
 *
 */
@interface COSQLiteStore : NSObject
{
@private
	NSURL *url_;
    FMDatabase *db_;
    
    NSMutableDictionary *backingStores_; // COUUID (backing store UUID => COCQLiteStorePersistentRootBackingStore)
    NSMutableDictionary *backingStoreUUIDForPersistentRootUUID_;
    
    /**
     * The user has called -beginTransaction.
     * This flag tells us internally we don't need to create extra transactions.
     */
    BOOL inUserTransaction_;
}

- (id)initWithURL: (NSURL*)aURL;
- (NSURL*)URL;

/** @taskunit Transactions */

/*
 These are purely for improving performance when making many changes at a time to the store.
 If you don't use them, transactions are created internally to ensure correct atomicity of all operations.
 */

- (void) beginTransaction;
- (void) commitTransaction;


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
- (COItem *) item: (COUUID *)anitem atRevisionID: (CORevisionID *)aToken;

/** @taskunit writing states */

- (CORevisionID *) writeItemTree: (COItemTree *)anItemTree
                    withMetadata: (NSDictionary *)metadata
            withParentRevisionID: (CORevisionID *)aParent
                   modifiedItems: (NSArray*)modifiedItems; // array of COUUID

/** @taskunit reading persistent roots */

- (NSArray *) persistentRootUUIDs;




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
                                                           metadata: (NSDictionary *)metadata;

- (COPersistentRootState *) createPersistentRootWithInitialRevision: (CORevisionID *)aRevision
                                                           metadata: (NSDictionary *)metadata;

- (BOOL) deletePersistentRoot: (COUUID *)aRoot;
- (BOOL) undeletePersistentRoot: (COUUID *)aRoot;

/* Undoable changes */

/**
 * Returns NO if the branch does not exist, or is deleted (finalized or not).
 */
- (BOOL) setCurrentBranch: (COUUID *)aBranch
		forPersistentRoot: (COUUID *)aRoot;

- (COUUID *) createBranchWithInitialRevision: (CORevisionID *)aToken
                                  setCurrent: (BOOL)setCurrent
                           forPersistentRoot: (COUUID *)aRoot;

/**
 * @return  a snapshot of the state of a persistent root, or nil if
 *          the persistent root does not exist.
 */
- (COPersistentRootState *) persistentRootWithUUID: (COUUID *)aUUID;

/**
 * If we care about detecting concurrent changes,
 * just add a fromVersoin: (token) paramater,
 * and within the transaction, fail if the current state is not the
 * fromVersion.
 */
- (BOOL) setCurrentVersion: (CORevisionID*)aVersion
                 forBranch: (COUUID *)aBranch
          ofPersistentRoot: (COUUID *)aRoot
                updateHead: (BOOL)updateHead;

/**
 * History compacting.
 *
 * Throws an exception if aVersion is not a parent of the current version and a child of the current tail.
 *
 * Reversible until -finalizeDeletions is called.
 */
- (BOOL) setTailRevision: (CORevisionID*)aVersion
               forBranch: (COUUID *)aBranch
        ofPersistentRoot: (COUUID *)aRoot;


- (BOOL) deleteBranch: (COUUID *)aBranch
     ofPersistentRoot: (COUUID *)aRoot;

- (BOOL) undeleteBranch: (COUUID *)aBranch
       ofPersistentRoot: (COUUID *)aRoot;

- (BOOL) setMetadata: (NSDictionary *)metadata
   forPersistentRoot: (COUUID *)aRoot;

- (BOOL) setMetadata: (NSDictionary *)metadata
           forBranch: (COUUID *)aBranch
    ofPersistentRoot: (COUUID *)aRoot;

/**
 * Finalizes the deletions of any deleted branches in the persistent root
 * or the persistent root itself.
 */
- (BOOL) finalizeDeletionsForPersistentRoot: (COUUID *)aRoot;

/* Search */

// Low-level search
- (NSArray *) revisionIDsMatchingQuery: (NSString *)aQuery;

@end
