#import <Foundation/Foundation.h>
#import "COPath.h"
#import "COStoreItem.h"
#import "COStore.h"
#import "COItemPath.h"
#import "COEditingContext.h"

@interface COPersistentRootEditingContext : NSObject <COEditingContext>
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
- (COStoreItem *) _storeItemForUUID: (ETUUID*) aUUID;

@end
