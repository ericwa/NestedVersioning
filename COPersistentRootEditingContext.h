#import <Foundation/Foundation.h>
#import "COPath.h"
#import "COStoreItem.h"
#import "COStore.h"
#import "COItemPath.h"

/**
 * a store api one level higher than COStore..
 * probably this will become the real COStore api once we switch to sqlite again
 
 

 how do we add undo/redo to this?
 for branches/roots that track a specific version, they should also have 
 a key/value called "tip". (terminology stolen from mercurial)
 
 - every commit to that branch root should set both "tracking" and "tip"
 to the same value.
 
 - to undo:
 a) look up the version that "tracking" points to
 b) get its parent (if it has none, can't undo)
 c) set "tracking" to the parent, without modifying tip
 
 - to redo:
 X = "tip"
 if (X == "tracking") fail ("can't redo")
 while (1) {
 if (X.parent == "tracking") {
 "tracking" = X;
 finshed;
 }
 X = X.parent;
 }
 
 **/




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
	COStore *store;
	
	//COPath *path;
	
	// we need to keep track of what the store state was when this editing cotext was created
	
	//COPath *absPath;
	/**
	 * for each element of absPath, the corresponding version UUID
	 */
	//NSArray *versionUUIDs;
	
	/**
	 * this is the commit we load our data from.
	 * when we make a commit, the parent of the commit will be set to this
	 */
	ETUUID *baseCommit;
	
	// -- persistent state
	
	NSMutableDictionary *existingItems;
	
	// -- in-memory mutable state which is "overlaid" on the 
	// persistent state represented by baseCommit
	
	NSMutableDictionary *insertedOrUpdatedItems;
	ETUUID *rootItem;
}

/**
 * note that this will create implict/hidden contexts for committing 
 * to all of the intermetiate roots in the path. This is ok, but it means
 * other contexts already open on those roots might have to do a merge
 * to apply their changes (either a trivial merge, most likely, or a conflict)
 */
//+ (COPersistentRootEditingContext *)contextForEditingPersistentRootAtPath: (COPath *)aPath;

- (id)initWithStore: (COStore *)aStore
		 commitUUID: (ETUUID*)aCommit; // if nil, creates a commit with no parent

/**
 * creates an empty context which will commit to a new version with no parent
 */
- (id)initWithStore: (COStore *)aStore;

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
 
 - the copied subtree is inserted into the given object in our context,
   at the specified index of the specified container property
 
 - there are several corner cases relating to overwriting objects:
     * if aUUID already exists in self, it is deleted from its current
	   location in self (which deletes all sub-objects).
     * if some of the children of aUUID in dest already exist in self,
       outside of the possible aUUID tree in self which the rule above
       handles, we should probably relabel those objects in the tree
       before it is inserted into self.
 
       e.g.: 
       -sketch1 has branch A and B.
	   -sketch1 starts in context X, and it is copied to context Y.
	   -branchA in context X is moved out of sketch1 to be a freestanding
        copy (keeps same UUID).
       -sketch1 is copied from context Y back to context X.
        the branch1 inside sketch1 from context Y conflicts with the
        freesranding branch1 in context X.
	   -it seems clear that contextY's skectch1 should overwrite context X's.
        however, the freestanding 'branch B" should not be affected/damaged.
        so, the skectch1.branchB should be given a new UUID.
 
 - note that the above is getting into UI policy territory, so maybe copying between
   contexts should be moved to a higher level of the API at some point.
 */
- (void) copyEmbeddedObject: (ETUUID*) aUUID
				fromContext: (COPersistentRootEditingContext*) aCtxt
					toIndex: (NSUInteger)i
			   ofCollection: (NSString*)attribute
				   inObject: (ETUUID*)anObject;

- (void) copyEmbeddedObject: (ETUUID*) aUUID
				fromContext: (COPersistentRootEditingContext*) aCtxt
	  toUnorderedCollection: (NSString*)attribute
				   inObject: (ETUUID*)anObject;


/**
 * - copies an embedded object and assigns it a new UUID.
 * - also copies all 'embedded' objects inside, and assigns
 * them new uuids.
 * - also updates all references in the copied subtree
 * from the old UUIDs to the new UUDIs
 *
 * @param aUUID the object to copy
 * @return the uuid of the copy of aUUID
 *
 */
- (ETUUID *) copyEmbeddedObject: (ETUUID*) aUUID
						toIndex: (NSUInteger)i
				   ofCollection: (NSString*)attribute
					   inObject: (ETUUID*)anObject;

- (ETUUID *) copyEmbeddedObject: (ETUUID*) aUUID
		  toUnorderedCollection: (NSString*)attribute
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


// copied from costorecontroller


/** @taskunit reading */

/**
 * converts a path to an "absolute path".
 
 a COPath can contain uuid's of roots that use any of the
 tracking types ("owned-branch" or "remote-root" or "remote-branch" or "version")
 
 however, roots with tracking types of "owned-branch" or "remote-root" or "remote-branch"
 are don't point directly to a version, but delegate that to another root/branch. this
 is analagous to a unix symlink.
 
 when committing or reading from the DB we want to convert a path which 
 may contain these "symlink" elements in it to a "real" path, i.e. one in which
 every path element is either a branch or a root with tracking type "version".
 that is an "absolute path"
 */
- (COPath *)absolutePathForPath: (COPath*)aPath;

/**
 * this is the core/primitive method for navigating a path.
 *
 * it needs to know how to navigate through the embedded objects
 * which represent persistent roots/branches.
 *
 * It returns the uuid of the current version which the path
 * points to.
 *
 * note that the logic for parsing persistent roots should be refactored.
 *
 * note that it is recursive.
 *
 * in the unix filesystem analogy this is like the "inode for path" method
 */
- (ETUUID*) currentVersionForPersistentRootAtPath: (COPath*)path;

/**
 * simple wrapper around -currentVersionForPersistentRootAtPath:
 * and -plistForEmbeddedObject:inCommit:
 */
- (id) plistForEmbeddedObject: (ETUUID*)embeddedObject
					   atPath: (COPath*)aPath;

/** @taskunit writing */

/**
 * this is the primitive method for writing changes to the store.
 * the objects parameter should contain _all_ objects in the persistent
 * root (not just modified ones).
 *
 * it handles updating the chain of persistent roots/branches in a path.
 *
 * note that is is recursive.
 *
 */
- (void) writeUUIDsAndPlists: (NSDictionary*)objects // ETUUID : plist
	 forPersistentRootAtPath: (COPath*)path
					metadata: (id)metadataPlist;

@end
