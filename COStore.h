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

- (ETUUID *) parentForCommit: (ETUUID*)commit;
- (id) metadataForCommit: (ETUUID*)commit;
- (NSDictionary *) UUIDsAndStoreItemsForCommit: (ETUUID*)commit;
- (ETUUID *) rootItemForCommit: (ETUUID*)commit;

- (COStoreItem *) storeItemForEmbeddedObject: (ETUUID*)embeddedObject
									inCommit: (ETUUID*)aCommitUUID;


/** @taskunit history cleaning */

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
- (void) deleteCommitsWithUUIDs: (NSArray*)uuids;



/**
 * This is a primitive/easy way of implementing the mutable part of the store
 */

/**
 * may return nil on first use.
 * 
 * You can use the following algorithm to GC inaccessible commits:
 *
 * void markVersion(aVersion) {
 *   if alreadyMarked(aVersion) {
 *     return;
 *   }
 *   foreach parent of aVersion {
 *     markVersion(parent);
 *   }
 *   foreach embeddedObject in aVersion {
 *     foreach attribute of embeddedObject {
 *       if attribute is a version reference {
 *         markVersion(referenced version);
 *       }
 *     }
 *   }
 * }
 * markVersion(rootVersion);
 *
 * -- now all unmarked versions can be permanently erased from disk.
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