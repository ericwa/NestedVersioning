#import <Foundation/Foundation.h>
#import "COPersistentRootEditingContext.h"

@interface COPersistentRootEditingContext (PersistentRoots)

// FIXME: Allow inserting in other places than the root!
/**
 * @returns the UUID of the persistent root item in the receiver
 */
- (ETUUID *)createAndInsertAsRootItemNewPersistentRootWithRootItem: (COStoreItem *)anItem; // FIXME: take a tree


@end
