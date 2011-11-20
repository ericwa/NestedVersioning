#import <Foundation/Foundation.h>
#import "COPath.h"

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
	COPath *path;
	
	// we need to keep track of what the store state was when this editing cotext was created
	
	COPath *absPath;
	/**
	 * for each element of absPath, the corresponding version UUID
	 */
	NSArray *versionUUIDs;
}

/**
 * note that this will create implict/hidden contexts for committing 
 * to all of the intermetiate roots in the path. This is ok, but it means
 * other contexts already open on those roots might have to do a merge
 * to apply their changes (either a trivial merge, most likely, or a conflict)
 */
+ (COPersistentRootEditingContext *)contextForEditingPersistentRootAtPath: (COPath *)aPath;

- (void) commit;



// maybe useful to have an API here which makes COObject unnecessary


- (ETUUID *)rootEmbeddedObject;

// read-only return value
- (COStoreItem *)storeItemForUUID: (ETUUID*) aUUID;


- (void) updateStoreItem: (COStoreItem *)anEditedItem;

// FIXME: think about api for creating new persistent roots.
// (copy existing (template?), or create blank/empty version/commit with
//  no parents)


@end
