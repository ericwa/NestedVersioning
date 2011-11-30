#import <Foundation/Foundation.h>

#import "COStoreItemTree.h"
#import "COItemPath.h"

@protocol COEditingContext <NSObject>

- (id<COEditingContext>) editingContextForEditingEmbdeddedPersistentRoot: (ETUUID*)aRoot;

- (ETUUID *) commitWithMetadata: (COStoreItemTree *)aTree;

/**
 * this embedded object defines object lifetime of all objects inside this
 * persistent root. i.e., for embedded objects to belong to this persistent
 * root they must be a child (or grand-child, etc.) of rootEmbeddedObject
 * through a kCOPrimitiveTypeEmbeddedObject relationship.
 */
- (ETUUID *)rootEmbeddedObject;

/**
 * Returns the union of all embedded objects in the base version
 * underlying this context, and any uncommitted in-memory objects added
 * to the context.
 */
- (NSSet *)allItemUUIDs;
/**
 * Same as above but returns COStoreItem instances
 */
- (NSSet *)allItems;
/**
 * returns a mutable copy which can be freely edited
 * without affecting anything.
 */
- (COStoreItem *)storeItemForUUID: (ETUUID*) aUUID;
/**
 * Returns an entire subtree
 */
- (COStoreItemTree *)storeItemTreeForUUID: (ETUUID*) aUUID;

- (NSSet *) allEmbeddedObjectUUIDsForUUID: (ETUUID*) aUUID;
- (NSSet *) allEmbeddedObjectUUIDsForUUIDInclusive: (ETUUID*) aUUID;
- (NSSet *) allEmbeddedItemsForUUIDInclusive: (ETUUID*) aUUID;

/* @taskunit editing methods */

- (void) updateItem: (COStoreItem*)anItem;
/**
 * Updates an entire subtree. throws an exception if any uuids in the
 * provided subtree are already in use.
 */
- (void) updateItemTree: (COStoreItemTree*)anItemTree;

/** 
 * throws an exception if any UUID's in aTree are already in use in this context
 */
- (void) insertItemTree: (COStoreItemTree *)aTree
			 atItemPath: (COItemPath*)anItemPath;

- (void) removeItemTreeAtItemPath: (COItemPath*)anItemPath;

- (void) moveItemAtPath: (COItemPath*)src toItemPath: (COItemPath*)dest;

@end