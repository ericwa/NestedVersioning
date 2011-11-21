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

// read-only return value
- (COStoreItem *)storeItemForUUID: (ETUUID*) aUUID;

- (NSSet *) allEmbeddedObjectUUIDsForUUID: (ETUUID*) aUUID;
- (NSSet *) allEmbeddedObjectUUIDsForUUIDInclusive: (ETUUID*) aUUID;

- (void) insertItem: (COStoreItem *)anItem;
- (void) updateItem: (COStoreItem *)anEditedItem;

// delete contained objects?
// what about external "holding" references?

- (void) deleteItemWithUUID: (ETUUID*)itemUUID;


// FIXME: think about api for creating new persistent roots.
// (copy existing (template?), or create blank/empty version/commit with
//  no parents)


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


@end
