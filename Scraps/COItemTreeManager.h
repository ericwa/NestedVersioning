#import <Foundation/Foundation.h>

#import "ETUUID.h"
#import "COFaultProvider.h"

@class COManagedItemTreeNode;
@class COItemTreeNode;

@interface COItemTreeManager : NSObject
{
	id <COFaultProvider> faultProvider; // weak reference
	
	ETUUID *cachedRootUUID;
	NSMutableDictionary *itemTreeNodeForUUID;
}

+ (COItemTreeManager *) treeManagerWithFaultProvider: (id<COFaultProvider>)aProvider;

/**
 * Returns the cached item tree (or creates a new instance and caches it if the
 * item isn't cached) for the given UUID.
 *
 * Returns nil if the fault provider doesn't have an item for this UUID.
 */
- (COManagedItemTreeNode *) itemTreeNodeForUUID: (ETUUID *)aUUID;

- (COManagedItemTreeNode *) rootItemTreeNode;
- (void) setRootItemTreeNode: (COItemTreeNode *)aTree;


@end
