#import <Cocoa/Cocoa.h>

#import "ETUUID.h"

/**
 * Factory for creating common objects
 */
@interface COItemFactory : NSObject
{
}
#if 0
- containerItem
- folderWithName:

/* @taskunit copy */

// copy within a context - renames everything
- (ETUUID *) copyEmbeddedObject: (ETUUID *)src
					 insertInto: (ETUUID *)dest
					  inContext: (id<COEditingContext>)ctx;

// inter-context copy
/*
 - when we copy/move an embedded object from one persistent root to another, it keeps the same uuid. are there any cases where this could cause problems? what if the destination already has objects with some/all of those uuids? probably keep the familiar filesystem semantics:
 • copy & paste in the same directory (for CO: in the same persistent root), and it makes sense to assign new UUIDs since otherwise the copy&paste would do nothing. 
 • copy & paste in to another directory (for CO: into another persistent root), and it makes sense to keep the same UUIDs, and overwrite any existing destination objects.
 
 
 */
- (ETUUID *) copyEmbeddedObject: (ETUUID *)src
					fromContext: (id<COEditingContext>)srcCtx;
					 insertInto: (ETUUID *)dest
					  inContext: (id<COEditingContext>)destCtx;



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


/* @taskunit persistent roots */

- (ETUUID *)newPersistentRootWithRootItem: (COStoreItem *)anItem
							   insertInto: (ETUUID *)destContainer
								inContext: (id<COEditingContext>)ctx;

- (NSSet *) branchesOfPersistentRoot: (ETUUID *)aRoot;
- (ETUUID *) currentBranchOfPersistentRoot: (ETUUID *)aRoot;
- (void) setCurrentBranch: (ETUUID*)aBranch
		forPersistentRoot: (ETUUID*)aUUID;

- (void) setTrackVersion: (ETUUID*)aVersion
			   forBranch: (ETUUID*)aBranch;

- (void) undoPersistentRoot: (ETUUID*)aRoot;
- (void) redoPersistentRoot: (ETUUID*)aRoot;

// special method for copying a branch out of a persistent root to create a standalone
// persistent root. see TestBranchesAndCopies.m
- (ETUUID *)newPersistentRootCopyingBranch: (ETUUID *)srcBranch
								insertInto: (ETUUID *)destContainer
								 inContext: (id<COEditingContext>)ctx;

/* @taskunit links */

- (ETUUID *)newLinkTo: (COPath*)aPath
		   insertInto: (ETUUID *)destContainer
			inContext: (id<COEditingContext>)ctx;


#endif

@end
