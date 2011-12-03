#import <Foundation/Foundation.h>
#import "COPersistentRootEditingContext.h"

@interface COPersistentRootEditingContext (PersistentRoots)

/**
 * @returns the UUID of the persistent root item in the receiver
 */
- (ETUUID *)createAndInsertNewPersistentRootWithRootItem: (COStoreItem *)anItem // FIXME: take a tree
										  inItemWithUUID: (ETUUID*)aDest;


@end
