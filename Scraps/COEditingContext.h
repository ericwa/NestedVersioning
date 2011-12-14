#import <Foundation/Foundation.h>
#import "COPath.h"
#import "COItem.h"
#import "COStore.h"
#import "COItemTreeNode.h"

@class COStore;

@interface COEditingContext : NSObject <NSCopying>
{
	id <COFaultProvider> faultProvider
	NSMutableDictionary *insertedOrUpdatedItems;
	ETUUID *rootItemUUID;
}

/** @taskunit creation */

+ (COEditingContext *) editingContext;

- (COEditingContext *) editingContextWithFaultProvider: (id<COFaultProvider>)aProvider;

- (id)copyWithZone:(NSZone *)zone;

- (COPath *) path;
- (COStore *) store;

/**
 * this embedded object defines object lifetime of all objects inside this
 * persistent root. i.e., for embedded objects to belong to this persistent
 * root they must be a child (or grand-child, etc.) of rootEmbeddedObject
 * through a kCOPrimitiveTypeEmbeddedObject relationship.
 */
- (ETUUID *)rootUUID;

- (COMutableItem *)rootItemTree;

/**
 * Returns an entire subtree
 */
- (COMutableItem *)storeItemTreeForUUID: (ETUUID*) aUUID;

/* @taskunit editing methods */

/**
 * Updates an entire subtree. throws an exception if any uuids in the
 * provided subtree are already in use, or if the item tree root does
 * not already exist in the context.
 */
- (void) updateItemTree: (COItemTreeNode*)anItemTree;

/** 
 * throws an exception if any UUID's in aTree are already in use in this context
 */
//- (void) insertItemTree: (COStoreItemTree *)aTree
//			 atItemPath: (COItemPath*)anItemPath;

//- (void) removeItemTreeAtItemPath: (COItemPath*)anItemPath;

//- (void) moveItemAtPath: (COItemPath*)src toItemPath: (COItemPath*)dest;


/**
 * Replace the entire contents of the receiver with the given item tree
 */
- (void) setItemTree: (COItemTreeNode *)aTree;

@end
