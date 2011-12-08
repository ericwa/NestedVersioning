#import <Foundation/Foundation.h>

#import "ETUUID.h"
#import "COFaultProvider.h"

@class COItemTreeNode;

@interface COItemTreeManager : NSObject
{
	id <COFaultProvider> faultProvider;
	
	NSMutableDictionary *itemTreeNodeForUUID;
}

+ (COItemTreeManager *) treeManagerWithFaultProvider: (id<COFaultProvider>)aProvider;

/**
 * Returns the cached item tree (or creates a new instance and caches it if the
 * item isn't cached) for the given UUID.
 *
 * Returns nil if the fault provider doesn't have an item for this UUID.
 */
- (COItemTreeNode *) itemTreeNodeForUUID: (ETUUID *)aUUID;

@end
