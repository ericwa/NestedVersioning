#import <Foundation/Foundation.h>
#import "COItemTreeNode.h"

@class COItemTreeManager;

/**
 * Subclass of COItemTreeNode which is owned by a item tree manager.
 */
@interface COManagedItemTreeNode : COItemTreeNode
{
	COItemTreeManager *manager; // Weak reference
}

- (BOOL) isFault;

- (COItemTreeManager *) manager;



/**
 * Returns a un-managed (COItemTreeNode) deep copy.
 * UUIDs of objects in the copied tree are unchanged.
 *
 * (Why not a tree of COManagedItemTreeNode instances? Because for a given
 *  COItemTreeManager, there is a 1:1 relationship between UUID and
 *  COManagedItemTreeNode.)
 */
- (id) copyWithZone: (NSZone*)aZone;

@end
