#import <Foundation/Foundation.h>
#import "COUUID.h"
#import "COItem.h"
#import "COPersistentRootEditingContext.h"

@class COSubtree;
@class COPersistentRootEditingContext;
@class COItem;
@class COPersistentRoot;
@class COPersistentRootState;
@class COPersistentRootStateDelta;
@class COPersistentRootStateToken;

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
 * Slow path. reads the entire state snapshot.
 */
- (COPersistentRootState *) fullStateForToken: (COPersistentRootStateToken *)aToken;

/**
 * Fast path. Returns the state for a given token, in the form of a delta against
 * another state. Which state the delta is based on is implementation defined
 * and has no semantic meaning. the token for that state will be returned in outBasedOn.
 *
 * The idea is to call this optimistically, if outBasedOn happens to return a state
 * that the caller has a full copy of in memory, they can use the delta, otherwise they must
 * call -fullStateForToken:.
 */
- (COPersistentRootStateDelta *) deltaStateForToken: (COPersistentRootStateToken *)aToken
                                            basedOn: (COPersistentRootStateToken **)outBasedOn;

// writing state
//
// no concurrency concerns exist here, because we're conceptually
// appending to a set and can never conflict with an exiting item.
//
// in practice we'll do it inside a transaction for the affected
// persistent root cache so we can get a unique id.

- (COPersistentRootStateToken *) addStateAsDelta: (COPersistentRootStateDelta *)aDelta
                                     parentState: (COPersistentRootStateToken *)parent;

- (COPersistentRootStateToken *) addState: (COPersistentRootState *)aFullSnapshot
                              parentState: (COPersistentRootStateToken *)parent;


/** @taskunit reading persistent roots */

- (NSArray *) allPersistentRootUUIDs;

// Returns a snapshot of the state of a persistent root.
- (COPersistentRoot *) persistentRootWithUUID: (COUUID *)aUUID;

/** @taskunit writing */

//
// Each of these mutates a SINGLE PERSISTENT ROOT.
//
// Atomicity: any changes made within a persistent root are atomic.
//

- (COPersistentRoot *) createPersistentRootWithInitialContents: (COPersistentRootState *)contents;

- (COPersistentRoot *) createCopyOfPersistentRoot: (COUUID *)aRoot;

// "exotic" method of creating proot
- (COPersistentRoot *)createPersistentRootByCopyingBranch: (COUUID *)aBranch
                                          ofPersistentRoot: (COUUID *)aRoot;

- (BOOL) deletePersistentRoot: (COUUID *)aRoot;

// branches

// note that these mutate the persistent roots, so any in-memory COPersistentRoots will be out of date

- (BOOL) deleteBranch: (COUUID *)aBranch
     ofPersistentRoot: (COUUID *)aRoot;

- (BOOL) setCurrentBranch: (COUUID *)aBranch
		forPersistentRoot: (COUUID *)aRoot;

- (COUUID *) createCopyOfBranch: (COUUID *)aBranch
			   ofPersistentRoot: (COUUID *)aRoot;

/**
 * If we care about detecting concurrent changes,
 * just add a fromVersoin: (token) paramater,
 * and within the transaction, fail if the current state is not the
 * fromVersion.
 */
- (BOOL) setCurrentVersion: (COPersistentRootStateToken*)aVersion
                 forBranch: (COUUID *)aBranch
          ofPersistentRoot: (COUUID *)aRoot;
	

/** @taskunit syntax sugar */

- (COPersistentRootState *) fullStateForPersistentRootWithUUID: (COUUID *)aUUID;
- (COPersistentRootState *) fullStateForPersistentRootWithUUID: (COUUID *)aUUID
                                                    branchUUID: (COUUID *)aBranch;

@end