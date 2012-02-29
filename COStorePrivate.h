#import <Foundation/Foundation.h>
#import "ETUUID.h"
#import "COItem.h"
#import "COStore.h"

@class COPersistentRootEditingContext;
@class COMutableItem;


@interface COStore (Private)

// TODO: how to handle disk full error? -> not much you can do
// db in use error? -> MUST retry and make sure the data gets committed

// TODO: think carefully about transaction atomicity - if a transaction is
// blocked because changes were made to the DB in the ﻿﻿meantime, what
// could need to be changed in the original transaction to finish committing it?

/** @taskunit commits */

- (ETUUID*) addCommitWithParent: (ETUUID*)parent
                       metadata: (id)metadataPlist
			 UUIDsAndStoreItems: (NSDictionary*)objects // ETUUID : COStoreItem
					   rootItem: (ETUUID*)root;

- (ETUUID*) addCommitWithParent: (ETUUID*)parent
                       metadata: (id)metadataPlist
						   tree: (COSubtree*)aTree;

- (NSArray*) allCommitUUIDs;

- (ETUUID *) parentForCommit: (ETUUID*)commit;
- (id) metadataForCommit: (ETUUID*)commit;
- (NSDate*) dateForCommit: (ETUUID*)commit;
- (NSDictionary *) UUIDsAndStoreItemsForCommit: (ETUUID*)commit;

/**
 * Returns the entire item tree for a commit
 */
- (COSubtree *) treeForCommit: (ETUUID *)aCommit;
/**
 * Returns the subtree of the entire item tree for a commit, starting from aUUID
 */
- (COSubtree *) subtreeForUUID: (ETUUID *)aUUID inCommit: (ETUUID *)aCommit;

- (ETUUID *) rootItemForCommit: (ETUUID*)commit;

- (COItem *) storeItemForEmbeddedObject: (ETUUID*)embeddedObject
									inCommit: (ETUUID*)aCommitUUID;


/**
 * "rooting problem"
 *
 * 1. have a 'root version' for the store, which changes on every commit to any persistent
 *    roots. toplevel persistent roots are just normal objects in the root version.
 *    May actually be OK unless we run in to problems with it.
 *    => this approach means the toplevel works just like deeper levels, except the top
 *       level doesn't have a "persistent root embedded object"/branch pointing at it.
 *    => this is equivelant to the top level version just being mutable.
 */

/**
 * may return nil on first use.
 */
- (ETUUID *) rootVersion;

/**
 * The versions set as the root version should not have parent pointers set,
 * because we don't keep history of the root version.
 *
 * If no parent version pointers are set, running gc will delete all but the
 * rootVersion, which is what we want.
 */
- (void) setRootVersion: (ETUUID*)version;

/** @taskunit one-to-many/many-to-many relationship caching */

/**
 * rationale: we only store (and version) one side of a relationship:
 * e.g., in a Boss we store a list of the Employees. (one-many relation)
 * in a Book we store a list of Tags. (many-many relation)
 *
 * why? because one side is calculated from the other. if we stored both sides
 * it would be easy for one to get out of sync with the other.
 *
 * to get the boss of an employee, or to get all the books that have a given tag,
 * we would have to do a linear scan. to avoid that, we maintain this cache.
 * 
 * note that it is just a discardable/regeneratable cache; not part of the actual
 * store data.
 */


@end