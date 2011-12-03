#import <Foundation/Foundation.h>

#import "COItemPath.h"

@protocol COEditingContext <NSObject>

/**
 * preconditions: (if not satisfied, the method should throw an exception)
 * 
 * - given the context has a path "u1/u2/u3../uN", 
 *   * path element u1 must be a persistent root in the store's top-level persistent root.
 *   * for each path element uI in the range u1..uN, the persistent root item uI must
 *     have a current branch child item which points to a version which represents 
 *     the contents of that persistent root.
 *
 */
- (ETUUID *) commitWithMetadata: (COStoreItem *)aTree;

/**
 * this embedded object defines object lifetime of all objects inside this
 * persistent root. i.e., for embedded objects to belong to this persistent
 * root they must be a child (or grand-child, etc.) of rootEmbeddedObject
 * through a kCOPrimitiveTypeEmbeddedObject relationship.
 */
- (ETUUID *)rootUUID;

- (COStoreItem *)rootItemTree;

/**
 * Returns an entire subtree
 */
- (COStoreItem *)storeItemTreeForUUID: (ETUUID*) aUUID;

/* @taskunit editing methods */

/**
 * Updates an entire subtree. throws an exception if any uuids in the
 * provided subtree are already in use, or if the item tree root does
 * not already exist in the context.
 */
//- (void) updateItemTree: (COStoreItemTree*)anItemTree;

/** 
 * throws an exception if any UUID's in aTree are already in use in this context
 */
//- (void) insertItemTree: (COStoreItemTree *)aTree
//			 atItemPath: (COItemPath*)anItemPath;

//- (void) removeItemTreeAtItemPath: (COItemPath*)anItemPath;

//- (void) moveItemAtPath: (COItemPath*)src toItemPath: (COItemPath*)dest;

// temporary protocol for updating... need to figure out a better one

- (void) _insertOrUpdateItems: (NSSet *)items
		newRootEmbeddedObject: (ETUUID*)aRoot;

- (void) _insertOrUpdateItems: (NSSet *)items;

@end
