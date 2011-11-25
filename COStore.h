#import <Foundation/Foundation.h>
#import "ETUUID.h"
#import "COStoreItem.h"

@class COStoreItem;

/**
 * lowest level of access to store.. deals with commit tree/forest.
 *
 * Most likely in the final version, the editing context layer will use COStoreController
 * and COStore will be a layer over SQLite (or COStoreController will use sqlite directly, maybe)
 
 comment on commit graph / merging:
 
 we should be able to employ exactly the same type of strategies as
 e.g. git. Being able to store multiple parents for a commit
 really is important.
 
 see http://codicesoftware.blogspot.com/2010/11/live-to-merge-merge-to-live.html
 quote:
 "So, what’s the benefit of merge tracking? It will just merge the changes 
 after the last merge happened, and you won’t have to solve the same manual 
 conflict again."
 
 */
@interface COStore : NSObject
{
@private
	NSURL *url;
}

// TODO: how to handle disk full error? -> not much you can do
// db in use error? -> MUST retry and make sure the data gets committed

// TODO: think carefully about transaction atomicity - if a transaction is
// blocked because changes were made to the DB in the ﻿﻿meantime, what
// could need to be changed in the original transaction to finish committing it?


/** @taskunit Initialization */

- (id)initWithURL: (NSURL*)aURL;
- (NSURL*)URL;

/** @taskunit commits */

- (ETUUID*) addCommitWithParent: (ETUUID*)parent
                       metadata: (id)metadataPlist
			 UUIDsAndStoreItems: (NSDictionary*)objects // ETUUID : COStoreItem
					   rootItem: (ETUUID*)root;

- (NSArray*) allCommitUUIDs;

// FIXME: Should change to "parents"
- (ETUUID *) parentForCommit: (ETUUID*)commit;
- (id) metadataForCommit: (ETUUID*)commit;
- (NSDictionary *) UUIDsAndStoreItemsForCommit: (ETUUID*)commit;
- (ETUUID *) rootItemForCommit: (ETUUID*)commit;

- (COStoreItem *) storeItemForEmbeddedObject: (ETUUID*)embeddedObject
									inCommit: (ETUUID*)aCommitUUID;


/** @taskunit history cleaning */

// ALL OF THESE SHOULD LOCK THE DB!

/**
 * permanently delete the specified commits.
 *
 * this guarantees not to affect any other commits, besides the listed ones.
 * (so, e.g., branches off of the listed commits will still work as before.)
 *
 * this will attempt to free disk space, but the amount freed
 * depends on how much of the data in the given commits is reused.
 * data not deleted now will be deleted later if it becomes garbage.
 */
- (void) deleteCommitsWithUUIDs: (NSSet*)uuids;

/**
 * implementing this will be non-trivial...
 * e.g., we can have a new branch created off of a very old commit which
 * is scheduled for deletion.
 *
 * x = scheduled for deletion
 * Y = not scheduled for deletion.
 *
 *          /---Y---...
 *         /
 * x---x---x---x---x---x---x---Y---...
 *
 * We should still be able to merge the two Y branches after the history cleaning.
 * 
 * a simple, conservative algorithim could be:
 * - delete all ancestors C of aCommit that satisfy all of:
 *     1. C is older than aDate
 *     2. all children of C are older than aDate
 *     3. C is not referenced explicitly by any embedded object in any commit
 *
 * - when a commit is deleted it should probably be left as a 'sentinel':
 *   this avoids mutating the history graph.
 *    
 */
- (void) deleteParentsOfCommit: (ETUUID*)aCommit
				 olderThanDate: (NSDate*)aDate;

/**
 * searches for unreachable commits and deletes them.
 * typical usage would be:
 *  1. permanently delete all commits on a persistent root older than a certain date
 *  2. run gc to delete any other commits which are no longer accessible as a result of (1.)
 */
- (void) gc;

/**
 * This is a primitive/easy way of implementing the mutable part of the store
 */

/**
 * may return nil on first use.
 */
- (ETUUID *) rootVersion;
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