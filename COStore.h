#import <Foundation/Foundation.h>
#import "COUUID.h"

#if 0
@class COItem;
@class COPersistentRootState;
@class COPersistentRootStateDelta;
@class CORevisionID;
@class CORevision;

extern NSString * const COStorePersistentRootMetadataDidChangeNotification;
extern NSString * const COStoreNotificationUUID;

/**
 * Snapshot of the state of a persistent root
 */
@protocol COPersistentRootMetadata <NSObject>

- (COUUID *) UUID;
- (NSArray *) branchUUIDs;
- (COUUID *) currentBranchUUID;
- (NSArray *) stateTokensForBranch: (COUUID *)aBranch;
- (CORevisionID *)currentStateForBranch: (COUUID *)aBranch;
- (NSDictionary *) metadata;

@end


@interface COStore : NSObject
{
@private
	NSURL *url;
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

/**
 * Slow path. reads the entire state snapshot.
 */
- (COPersistentRootState *) fullStateForToken: (CORevisionID *)aToken;

/**
 * Fast path. Returns the state for a given token, in the form of a delta against
 * another state. Which state the delta is based on is implementation defined
 * and has no semantic meaning. the token for that state will be returned in outBasedOn.
 *
 * The idea is to call this optimistically, if outBasedOn happens to return a state
 * that the caller has a full copy of in memory, they can use the delta, otherwise they must
 * call -fullStateForToken:.
 */
- (COPersistentRootStateDelta *) deltaStateForToken: (CORevisionID *)aToken
                                            basedOn: (CORevisionID **)outBasedOn;

// writing state
//
// no concurrency concerns exist here, because we're conceptually
// appending to a set and can never conflict with an exiting item.
//
// in practice we'll do it inside a transaction for the affected
// persistent root cache so we can get a unique id.

- (CORevisionID *) addStateAsDelta: (COPersistentRootStateDelta *)aDelta
                                     parentState: (CORevisionID *)parent;

- (CORevisionID *) addState: (COPersistentRootState *)aFullSnapshot
                              parentState: (CORevisionID *)parent;


/** @taskunit reading persistent roots */

- (NSArray *) allPersistentRootUUIDs;

// Returns a snapshot of the state of a persistent root.
- (id <COPersistentRootMetadata>) persistentRootWithUUID: (COUUID *)aUUID;

/** @taskunit writing */

//
// Each of these mutates a SINGLE PERSISTENT ROOT.
//
// Atomicity: any changes made within a persistent root are atomic.
//

- (COUUID *) createPersistentRootWithInitialContents: (COPersistentRootState *)contents
                                            metadata: (NSDictionary *)metadata;

- (COUUID *) createPersistentRootWithInitialRevision: (CORevisionID *)aRevision
                                            metadata: (NSDictionary *)metadata;
- (BOOL) deletePersistentRoot: (COUUID *)aRoot;

// branches

// note that these mutate the persistent roots, so any in-memory COPersistentRoots will be out of date

- (BOOL) setCurrentBranch: (COUUID *)aBranch
		forPersistentRoot: (COUUID *)aRoot;

- (BOOL) createBranchWithUUID: (COUUID *)aBranch
             withInitialState: (CORevisionID *)aToken
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
	

/** @taskunit syntax sugar */

- (COPersistentRootState *) fullStateForPersistentRootWithUUID: (COUUID *)aUUID;
- (COPersistentRootState *) fullStateForPersistentRootWithUUID: (COUUID *)aUUID
                                                    branchUUID: (COUUID *)aBranch;


@end
#endif