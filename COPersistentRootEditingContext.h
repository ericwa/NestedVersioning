#import <Foundation/Foundation.h>
#import "COPath.h"
#import "COStoreItem.h"
#import "COStore.h"
#import "COStoreItemTree.h"

@class COStore;

@interface COPersistentRootEditingContext : NSObject
{
	COStore *store;
	
	COPath *path;
	
	/**
	 * this is the commit we load our data from.
	 * when we make a commit, the parent of the commit will be set to this.
	 *
	 * if the branch we are editing has been changed from this value,
	 * we will need to do a merge
	 */
	ETUUID *baseCommit;
		
	// -- in-memory mutable state which is "overlaid" on the 
	// persistent state represented by baseCommit
	
	NSMutableDictionary *insertedOrUpdatedItems;
	ETUUID *rootItemUUID;
}

/** @taskunit creation */

+ (COPersistentRootEditingContext *) editingContextForEditingPath: (COPath*)aPath
														  inStore: (COStore *)aStore;

- (COPersistentRootEditingContext *) editingContextForEditingEmbdeddedPersistentRoot: (ETUUID*)aRoot;

/**
 * private method; public users should use -[COStore rootContext].
 */
+ (COPersistentRootEditingContext *) editingContextForEditingTopLevelOfStore: (COStore *)aStore;

/**
 * returns an independent copy.
 * FIXME: would it be useful to have a copy without any local changes?
 */
//- (id)copyWithZone:(NSZone *)zone;

- (COPath *) path;
- (COStore *) store;

/** @taskunit private */
- (COMutableStoreItem *) _storeItemForUUID: (ETUUID*) aUUID;

/** @taskunit COEditingContext */

/**
 * preconditions: (if not satisfied, the method should throw an exception)
 *  - the provided UUID must identify a valid persistent root item in the
 *    reciever, which has a valid branch child, which point to an (existing) store commit/version.
 *    These must be committed already, not just in-memory.
 *  
 *  - one corner case is where the persistent root exists, but in-memory it is switched
 *    to a different (new) branch. However this method completely ignore the receiver context;
 *    the only information it uses in the receiver is [self path].
 */
- (COPersistentRootEditingContext *) editingContextForEditingEmbdeddedPersistentRoot: (ETUUID*)aRoot;

/**
 * same preconditions as above
 */
- (COPersistentRootEditingContext *) editingContextForEditingEmbdeddedPersistentRoot: (ETUUID*)aRoot
																			onBranch: (ETUUID*)aBranch;


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
- (ETUUID *) commitWithMetadata: (COMutableStoreItem *)aTree;

/**
 * this embedded object defines object lifetime of all objects inside this
 * persistent root. i.e., for embedded objects to belong to this persistent
 * root they must be a child (or grand-child, etc.) of rootEmbeddedObject
 * through a kCOPrimitiveTypeEmbeddedObject relationship.
 */
- (ETUUID *)rootUUID;

- (COMutableStoreItem *)rootItemTree;

/**
 * Returns an entire subtree
 */
- (COMutableStoreItem *)storeItemTreeForUUID: (ETUUID*) aUUID;

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

/**
 * Replace the entire contents of the receiver with the given item tree
 */
- (void) setItemTree: (COStoreItemTree *)aTree;

@end
