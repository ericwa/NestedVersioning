#import <Foundation/Foundation.h>

@protocol COEditingContext <NSObject>



- (ETUUID *) commit;
/**
 * does a commit and records in the metadata
 * these commit UUIDs as being additional parents
 */
- (void) commitWithMergedVersionUUIDs: (NSArray*)anArray;


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

- (NSSet *) allEmbeddedObjectUUIDsForUUID: (ETUUID*) aUUID;
- (NSSet *) allEmbeddedObjectUUIDsForUUIDInclusive: (ETUUID*) aUUID;
- (NSSet *) allEmbeddedItemsForUUIDInclusive: (ETUUID*) aUUID;

/**
 * After calling, consistency of kCOPrimitiveTypeEmbeddedObject references
 * is checked/enforced. inconsistency results in an exception being thrown.
 * Unreachable objects after calling this are deleted.
 */
- (void) insertOrUpdateItems: (NSSet *)items
	   newRootEmbeddedObject: (ETUUID*)aRoot;

- (void) insertOrUpdateItems: (NSSet *)items;

- (void) insertItemWithUUID: (ETUUID *)aUUID
					  items: (NSSet *)items
					atIndex: (NSUInteger)i
			   ofCollection: (NSString*)attribute
				   inObject: (ETUUID*)anObject;

- (void) insertItemWithUUID: (ETUUID *)aUUID
					  items: (NSSet *)items
			   inCollection: (NSString*)attribute
				   inObject: (ETUUID*)anObject;


/* @taskunit persistent roots (TODO: move to class?) */

- (ETUUID *) newPersistentRootAtItemPath: (COItemPath*)aPath;

- (NSSet *) branchesOfPersistentRoot: (ETUUID *)aRoot;
- (ETUUID *) currentBranchOfPersistentRoot: (ETUUID *)aRoot;
- (void) setCurrentBranch: (ETUUID*)aBranch
		forPersistentRoot: (ETUUID*)aUUID;


- (void) setTrackRemoteBranchOrRoot: (COPath*)aPath
						  forBranch: (ETUUID*)aBranch;

- (void) setTrackVersion: (ETUUID*)aVersion
			   forBranch: (ETUUID*)aBranch;

- (void) undoPersistentRoot: (ETUUID*)aRoot;
- (void) redoPersistentRoot: (ETUUID*)aRoot;

@end
