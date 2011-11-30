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
- (ETUUID *)rootUUID;

- (COStoreItemTree *)rootItemTree;

/**
 * Returns an entire subtree
 */
- (COStoreItemTree *)storeItemTreeForUUID: (ETUUID*) aUUID;

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

@end
