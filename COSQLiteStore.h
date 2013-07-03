#import <Foundation/Foundation.h>

@class COUUID;
@class COItem;
@class CORevisionID;
@class CORevision;
@class COItemGraph;
@class FMDatabase;
@class COPersistentRootInfo;

@interface COBranchInfo : NSObject
{
@private
    COUUID *uuid_;
    CORevisionID *headRevisionId_;
    CORevisionID *tailRevisionId_;
    CORevisionID *currentState_;
    NSDictionary *metadata_;
    BOOL deleted_;
}

@property (readwrite, nonatomic, retain) COUUID *UUID;
@property (readwrite, nonatomic, retain) CORevisionID *headRevisionID;
@property (readwrite, nonatomic, retain) CORevisionID *tailRevisionID;
@property (readwrite, nonatomic, retain) CORevisionID *currentRevisionID;
@property (readwrite, nonatomic, retain) NSDictionary *metadata;
@property (readwrite, nonatomic, getter=isDeleted, setter=setDeleted:) BOOL deleted;

@end

@interface COPersistentRootInfo : NSObject
{
@private
    COUUID *uuid_;
    COUUID *currentBranch_;
    COUUID *mainBranch_;
    NSMutableDictionary *branchForUUID_; // COUUID : COBranchPlist
}

- (NSSet *) branchUUIDs;

- (COBranchInfo *)branchInfoForUUID: (COUUID *)aUUID;
- (COBranchInfo *)currentBranchInfo;

@property (readwrite, nonatomic, retain) COUUID *UUID;
@property (readwrite, nonatomic, retain) COUUID *currentBranchUUID;
@property (readwrite, nonatomic, retain) COUUID *mainBranchUUID;
@property (readwrite, nonatomic, retain) NSDictionary *branchForUUID;

@end

/**
 * This class implements a Core Object store using SQLite databases.
 *
 * Conceptual model
 * ----------------
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
 *       This metadata is not interpreted or used by COSQLiteStore.
 *
 *   A _branch_ consists of a linear sequence of _revisions_:  A _revision_ is a snapshot of the 
 *   persistent root contents. It also records its parent. In the future, metadata could be added per-revision.
 *
 *   The revisions in a branch are produced by making
 *   sequential edits to the _contents_ of the persistent root.
 *
 *   There is a  marker indicating the current revision, as well as two special revsions called
 *   "head" and "tail".
 *
 *   oldest           newest
 *     o--------o--------o
 *    tail    current   head
 *
 *   The purpose of the head and tail pointers is to keep track of all revisions that have ever
 *   been committed to a branch. The tail represents the start of the recorded history of the branch,
 *   the head represents the newest. Normally the current revision is the same as the head,
 *   but the current revision could be moved to an older revision if the user wants to revert to an
 *   older sate.
 *
 *   Note: making a commit when the current branch is an older than the head revision would mean
 *   that the old head is lost. When exposing this functionality in the UI, the user should
 *   probably be encouraged/forced to make a new branch so that the old head isn't lost.
 *
 *   oldest                newest
 *
 *               /------------o
 *              /            new head
 *     o--------o . . . . o
 *    tail    current   (lost head)
 *
 *   (Note that if -finalizeDeletionsForPersistentRoot: is called in this state, the dotted revisions
 *   will be lost forever.) History compaction is accomplished by moving the tail pointer forward,
 *   and calling -finalizeDeletionsForPersistentRoot:.
 *
 *   The contents of a revision consists of a graph of
 *   _embedded objects_, along with one designated as the _root embedded object_. The designation
 *   of _root embedded object_ is for users' convenience; the intent is that this object is what
 *   the persistent root represents. Note that the root embedded object does not have the same UUID
 *   as the _persistent root_ that contains it.
 *
 *   Persistent roots and branches are mutable, and any changes made are unversioned (only the current
 *   state is stored.) Undo/redo should be implemented at a higher layer by logging changes made
 *   to the store.
 *
 *   The revisions of the versioned contents are stored in a DAG structure. Each revision is
 *   identified by, currently, an opaque ID (internally, backing store UUID + an integer).
 *   A hash, like git and other dvcs's use, could be used instead - the current scheme was chosen for
 *   simplicity and speculated better performance but we may switch to a hash.
 *
 *   TODO: Explain the propety types of embedded objects that are relevant to COSQLiteStore:
 *   Attachment ID, path (inter-persistent root reference)
 *
 * Basic Usage
 * -----------
 *
 * - The basic usage pattern is:
 *
 *    * Create a persistent root with -createPersistentRootWithInitialContents:metadata:,
 *      or -createPersistentRootWithInitialRevision:metadata: if a cheap copy is desired.
 *
 *    * Write an embedded object graph as a revision using -writeItemTree:withMetadata:withParentRevisionID:modifiedItems:.
 *
 *    * Set the current version of the persistent root's current version to the newly committed
 *      revision using -setCurrentVersion:forBranch:ofPersistentRoot:updateHead:
 *
 *    * Read back the embedded object graph at an old revision using -itemTreeForRevisionID:
 *
 * - Note that there is no deliberatly no support for copying persistent roots.
 *
 *
 *
 *
 * Garbage collection / deletion semantics
 * ---------------------------------------
 *
 * - Persistent roots are never garbage collected, they must be deleted explicitly by the user. [1]
 *   For convenience, once deleted, they can be undeleted. Typical use case:
 *        - user creates a document, types in it a bit.
 *        - It's a temporary note, so when they're done with it, they delete it.
 *        - The note is moved to the trash. CMD+Z undoes the move to trash.
 *   So by having the not deleted/deleted flag at the store level, we can easily
 *   make "delete" a command-pattern invertible undo action.
 *
 * - There are attachments which are stored separately from the revision data in backing stores,
 *   however from the point of view of data lifetime, it's as if the attachment is part of the revision
 *   data in the backing store.
 *
 * - Branches can be deleted. Like persistent roots, they can be undeleted, and the list of deleted braches
 *   for a persistent root can be queried.  
 *
 * - There is a "finalize deletions" command that the user can invoke on a persistent root, which permanently removes:
 *   * the persistent root, if it is marked as deleted
 *   * branches of the persistent root marked as deleted
 *   * all unreachable revisions in the same backing store as the persistent root
 *
 * - Additionally there is a separate command to delete all unreachable attachments in the store
 *
 * - Over time, the user may want to prune the history of a branch. This is implemented
 *   by moving ahead the 'base' pointer of a branch, and performing a "finalize deletions" command on the
 *   persistent root.
 * 
 * - Since "finalize deletions" actually deletes data and frees disk space, there are the following
 *   side effects:
 *   * Calling -undeletePersistentRoot: will return NO if "finalize deletions" has been performed
 *     since the persistent root was deleted with -deletePersistentRoot:
 *   * Calling -undeleteBranch: will return NO if "finalize deletions" has been performed
 *     since the branch was deleted with -deleteBranch:
 *   * Calling -setCurrentVersion:... will return NO if the revision has been deleted.
 * 
 * Implementation summary
 * ----------------------
 *
 * - COSQLiteStore has one SQLite database which stores the persistent root and branch metadata,
 *   as well as full text indexes and an index of attachment references (for garbage collecting attachments),
 *   and an index of cross-persistent root references (not used for anything internally, but exposed to
 *   users of the class so we can quickly answer questions like "show all references to this persistent root")
 *
 * - Persistent root contents are stored in "backing stores". See COSQLiteStorePersistentRootBackingStore.
 *
 *
 * Concurrency
 * -----------
 *
 * COSQLiteStore is designed to support multiple processes having the same store opening and making concurrent
 * changes. (at the moment it's not tested.)
 *
 * The only pieces of shared mutable state are the persistent root (and branch) metadata (current branch, 
 * current revision), and right now there is no synchronization mechanisim for multiple processes to coordinate
 * making a change... this will be needed.
 *
 * One idea was to add a fromVersion: paramater to -setCurrentVersion:forBranch:...,  and within the transaction, 
 * fail if the current state is not the fromVersion.
 *
 * Footnotes
 * ---------
 *
 * [1] Deletion modes: There are two designs we could have used for persistent root deletion:
 *   - 1. explicit deletion
 *   - 2. garbage collection
 *
 *   In the "explicit deletion" design, which is what we are using, persistent roots are never deleted
 *   unless explicitly removed by the user. In addition, I setteled on a two step deletion, where first
 *   the user calls -deletePersistentRoot:, and then -finalizeDeletionsForPersistentRoot: to permanently delete it.
 *
 *   The garbage collection design has serious problems. I was going to allow the user to designate some
 *   persistent roots as GC roots, which would never be garbage collected, and the rest would be eligible
 *   for collection unless there was a reference to them somehow. This is where the scheme starts to fall apart:
 *
 *   - if "old" references (that exist in old revisions but not in newer) keep a persistent root alive,
 *     then it becomes very difficult to ever delete persistent roots. Suppose you create a temporary
 *     persistent root T, and a reference to it in a long-lived workspace persistent root W.
 *     Later, the reference in W is deleted.
 *     The only way to have T's underlying disk space freed would be to erase all history of W up to the
 *     point where the reference to T was deleted. To fix this we'd have to curcumvent the GC by doing manual deletion,
 *     making the effort of doing GC wasted.
 *
 *  - a possible scheme could be, only references in the current version of all branches of all persistent roots
 *    are counted as keeping other persistent roots alive.
 *    This sceheme has a lot of problems:
 *
 *     * Could lead to accidental deletion if you temporairly revert the workspace W to an old version
 *       and a GC is triggered; then all documents referenced only by W after the point you reveted to
 *       will be permanently deleted.
 *
 *     * Hard to implement efficiently.
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

/**
 * Opens an exisiting, or creates a new CoreObject store at the given file:// URL.
 */
- (id)initWithURL: (NSURL*)aURL;

/**
 * Returns the file:// URL the receiver was created with.
 */
- (NSURL*)URL;




/** @taskunit Revision Reading */

/**
 * Read revision metadata for a given revision ID.
 *
 * This data in the store is immutable (except for the case that the revision becomes unreachable and is garbage collected
 * by a call to -finalizeDeletionsForPersistentRoot), and so it could be cached in memory by COSQLiteStore (though isn't currently)
 * 
 * Adding an in-memory cache for this will probably imporant.
 */
- (CORevision *) revisionInfoForRevisionID: (CORevisionID *)aToken;

/**
 * Returns a delta between the given revision IDs.
 * The delta is uses the granularity of single embedded objects, but not individual properties.
 *
 * This is only useful if the caller has the state of baseRevid in memory.
 * 
 * In the future if we add an internal in-memory revision cache to COSQLiteStore, this may
 * no longer be of much use.
 */
- (COItemGraph *) partialContentsFromRevisionID: (CORevisionID *)baseRevid
                                  toRevisionID: (CORevisionID *)finalRevid;

/**
 * Returns the state the embedded object graph at a given revision.
 */
- (COItemGraph *) contentsForRevisionID: (CORevisionID *)aToken;

/**
 * Returns the state of a single embedded object at a given revision.
 */
- (COItem *) item: (COUUID *)anitem atRevisionID: (CORevisionID *)aToken;





/** @taskunit Revision Writing */

/**
 * Writes an embedded object graph as a revision in the store.
 *
 * aParent determines the backing store to write the revision to; must be non-null.
 * modifiedItems is an array of the UUIDs of objects in anItemTree that were either added or changed from their state
 *     in aParent. nil can be passed to indicate that all embedded objects were new/changed. This parameter
 *     is the delta compression, so it should be provided and must be accurate.
 *
 *     For optimal ease-of-use, this paramater would be removed, and the aParent revision would be feteched
 *     from disk or memory and compared to anItemTree to compute the modifiedItems set. Only problem is this
 *     requires comparing all items in the trees, which is fairly expensive.
 */
- (CORevisionID *) writeContents: (COItemGraph *)anItemTree
                    withMetadata: (NSDictionary *)metadata
                parentRevisionID: (CORevisionID *)aParent
                   modifiedItems: (NSArray*)modifiedItems;




/** @taskunit Persistent Root Creation */

/**
 * Standard method to create a persistent root.
 *
 * Always creates a new backing store, so the contents will not be stored as a delta against another
 * persistent root. If the new persistent root is likely going to have content in common with another
 * persistent root, use -createPersistentRootWithInitialRevision:metadata: instead.
 */
- (COPersistentRootInfo *) createPersistentRootWithInitialContents: (COItemGraph *)contents
                                                           metadata: (NSDictionary *)metadata;

/**
 * "Cheap copy" method of creating a persistent root.
 *
 * The created persistent root will have a single branch whose current revision is set to the
 * provided revision.
 *
 * The persistent root will share its backing store with the backing store of aRevision,
 * but this is an implementation detail and otherwise it's completely isolated from other
 * persistent roots sharing the same backing store. 
 * 
 * (The only way that sharing backing stores should be visible to uses is a corner case in 
 * the behaviour of -finalizeDeletionsForPersistentRoot:. It will garbage collect all unreferenced
 * revisions in the backing store of the passed in persistent root)
 */
- (COPersistentRootInfo *) createPersistentRootWithInitialRevision: (CORevisionID *)aRevision
                                                           metadata: (NSDictionary *)metadata;




/** @taskunit Persistent Root Reading */

/**
 * Only returns non-deleted persistent root UUIDs.
 */
- (NSArray *) persistentRootUUIDs;
- (NSArray *) deletedPersistentRootUUIDs;

/**
 * @return  a snapshot of the state of a persistent root, or nil if
 *          the persistent root does not exist.
 */
- (COPersistentRootInfo *) persistentRootWithUUID: (COUUID *)aUUID;




/** @taskunit Persistent Root Modification */

/**
 * Sets the current branch. The current branch is not used internally but intended
 * to be used by COSQLiteStore users as the default branch to display when the user
 * opens a persistent root.
 *
 * Returns NO if the branch does not exist, or is deleted (finalized or not).
 */
- (BOOL) setCurrentBranch: (COUUID *)aBranch
		forPersistentRoot: (COUUID *)aRoot;

/**
 * Sets the main branch. The main branch is used to resolve inter-persistent-root references
 * when no explicit branch is named.
 *
 * Returns NO if the branch does not exist, or is deleted (finalized or not).
 */
- (BOOL) setMainBranch: (COUUID *)aBranch
     forPersistentRoot: (COUUID *)aRoot;

- (COUUID *) createBranchWithInitialRevision: (CORevisionID *)aToken
                                  setCurrent: (BOOL)setCurrent
                           forPersistentRoot: (COUUID *)aRoot;

/**
 * All-in-one method for updating the current revision of a persistent root.
 *
 * Passing nil for any revision params means to keep the current value
 */
- (BOOL) setCurrentRevision: (CORevisionID*)currentRev
               headRevision: (CORevisionID*)headRev
               tailRevision: (CORevisionID*)tailRev
                  forBranch: (COUUID *)aBranch
           ofPersistentRoot: (COUUID *)aRoot;


- (BOOL) setMetadata: (NSDictionary *)metadata
   forPersistentRoot: (COUUID *)aRoot;

- (BOOL) setMetadata: (NSDictionary *)metadata
           forBranch: (COUUID *)aBranch
    ofPersistentRoot: (COUUID *)aRoot;

/** @taskunit Persistent Root Deletion */

/**
 * Marks the given persistent root as deleted, can be reverted by -undeletePersistentRoot:.
 * Will be permanently removed when -finalizeDeletionsForPersistentRoot: is called.
 */
- (BOOL) deletePersistentRoot: (COUUID *)aRoot;

/**
 * Unmarks the given persistent root as deleted
 */
- (BOOL) undeletePersistentRoot: (COUUID *)aRoot;

/**
 * Marks the given branch of the persistent root as deleted, can be reverted by -undeleteBranch:ofPersistentRoot:.
 * Will be permanently removed when -finalizeDeletionsForPersistentRoot: is called.
 */
- (BOOL) deleteBranch: (COUUID *)aBranch
     ofPersistentRoot: (COUUID *)aRoot;

/**
 * Unmarks the given branch of a persistent root as deleted
 */
- (BOOL) undeleteBranch: (COUUID *)aBranch
       ofPersistentRoot: (COUUID *)aRoot;

/**
 * Finalizes the deletion of any unreachable commits (whether due to -setTailRevision:... moving the tail pointer,
 * or branches being deleted), any deleted branches, or the persistent root itself, as well as all unreachable
 * attachments.
 */
- (BOOL) finalizeDeletionsForPersistentRoot: (COUUID *)aRoot;




/** @taskunit Search. API not final. */

/**
 * @returns an array of CORevisionID
 */
- (NSArray *) revisionIDsMatchingQuery: (NSString *)aQuery;

/**
 * @returns an array of COSearchResult
 */
- (NSArray *) referencesToPersistentRoot: (COUUID *)aUUID;


/** @taskunit Transactions. API not final. */

/**
 * Starts a transaction, purely for improving performance when making a batch of changes.
 * Should not normally be used, except for in batch imports.
 */
- (void) beginTransaction;
- (void) commitTransaction;

@end
