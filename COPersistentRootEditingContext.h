#import <Foundation/Foundation.h>
#import "COPath.h"
#import "COStoreItem.h"
#import "COStore.h"
#import "COItemPath.h"
#import "COEditingContext.h"

@interface COPersistentRootEditingContext : NSObject <COEditingContext>
{
	COStore *store;
	
	COPath *absPath;
	
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
