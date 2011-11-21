#import <Foundation/Foundation.h>
#import "COPath.h"
#import "COStoreController.h"
#import "COStoreItem.h"
#import "COStore.h"

/**
 * an object context handles the process of committing changes.
 *
 * committing to a persistent root nested several roots deep necessitates
 * commits in every parent.
 
 how to get rid of the cyclic nature of this class?
 i.e. to commit changes to an embedded object requires knowing how to commit changes to its
 parent persistent root.
 
 */
@interface COPersistentRootEditingContext : NSObject
{
	COStoreController *sc;
	COStore *store;
	
	COPath *path;
	
	// we need to keep track of what the store state was when this editing cotext was created
	
	COPath *absPath;
	/**
	 * for each element of absPath, the corresponding version UUID
	 */
	NSArray *versionUUIDs;
	
	/**
	 * this is the commit we load our data from.
	 * when we make a commit, the parent of the commit will be set to this
	 */
	ETUUID *baseCommit;
	
	// -- in-memory mutable state which is "overlaid" on the 
	// persistent state represented by baseCommit
	
	NSMutableDictionary *insertedOrUpdatedItems;
	NSMutableSet *deletedItems;
}

/**
 * note that this will create implict/hidden contexts for committing 
 * to all of the intermetiate roots in the path. This is ok, but it means
 * other contexts already open on those roots might have to do a merge
 * to apply their changes (either a trivial merge, most likely, or a conflict)
 */
+ (COPersistentRootEditingContext *)contextForEditingPersistentRootAtPath: (COPath *)aPath;

- (void) commit;
/**
 * does a commit and records in the metadata
 * these commit UUIDs as being additional parents
 */
- (void) commitWithMergedVersionUUIDs: (NSArray*)anArray;


// maybe useful to have an API here which makes COObject unnecessary


- (ETUUID *)rootEmbeddedObject;

/**
 * returns a mutable copy which can be freely edited
 * without affecting anything.
 */
- (COStoreItem *)storeItemForUUID: (ETUUID*) aUUID;

- (NSSet *) allEmbeddedObjectUUIDsForUUID: (ETUUID*) aUUID;
- (NSSet *) allEmbeddedObjectUUIDsForUUIDInclusive: (ETUUID*) aUUID;

/** maybe we need: */
//- (void) insertConsistentSetOfItems: (COSet <COStoreItem*>*) items;
/* which checks for kCOPrimitiveTypeEmbeddedItem consistency 
   after the insertion, and fixes up any inconsistencies? 
 */

- (void) insertItem: (COStoreItem *)anItem;
- (void) updateItem: (COStoreItem *)anEditedItem;

// delete contained objects?
// what about external "holding" references?

- (void) deleteItemWithUUID: (ETUUID*)itemUUID;


/**
 * copies an embedded object from another context.
 
 detailed semantics:
 - this is the method to use for copying a persistent root, 
   as well as for normal embedded objects (it contains no special
   handling for persistent roots, but just works. *although
   we may want to add special handling for the relative paths
   problem)
 
 - uuids are not changed / remapped.
 
 - referenced objects with reference type kCOPrimitiveTypeEmbeddedObject
   are copied as well. their uuids stay the same
 
 
 */
- (void) copyEmbeddedObject: (ETUUID*) aUUID
				fromContext: (COPersistentRootEditingContext*) aCtxt;


/**
 * - copies an embedded object and assigns it a new UUID.
 * - also copies all 'embedded' objects inside, and assigns
 * them new uuids.
 * - also updates all references in the copied subtree
 * from the old UUIDs to the new UUDIs
 * - this method only calls [self insertItem: ]
 *
 * @param aUUID the object to copy
 * @return the uuid of the copy of aUUID
 *
 */
- (ETUUID *) copyEmbeddedObject: (ETUUID *)aUUID;


/* @taskunit persistent roots (TODO: move to class?) */

- (ETUUID *) newPersistentRoot;
- (NSArray *) branchesOfPersistentRoot: (ETUUID *)aRoot;
/*
- setRootToOneOfItsBranches
- setRootToRemoteBranchOrRoot
- setRootToSpecificVersion
...
*/

- (void) undoForPersistentRoot: (ETUUID*)aRoot;
- (void) redoForPersistentRoot: (ETUUID*)aRoot;
@end
