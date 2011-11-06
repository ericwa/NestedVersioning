#import <Foundation/Foundation.h>
#import "ETUUID.h"

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
                       metadata: (NSData*)metadata
				   UUIDsAndData: (NSDictionary*)objects; // ETUUID : NSData

- (NSArray*) allCommitUUIDs;

- (ETUUID *) parentForCommit: (ETUUID*)commit;
- (NSData *) metadataForCommit: (ETUUID*)commit;
- (NSDictionary *) UUIDsAndDataForCommit: (ETUUID*)commit;

/** @taskunit persistent roots */

- (NSArray *) persistentRootUUIDs;



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