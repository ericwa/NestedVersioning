#import <Foundation/Foundation.h>
#import "COItemTreeNode.h"

/**
 * Tree node that gets its data from a fault provider. when the fault provider
 * changes, it needs to re-fetch the state.
 */
@interface COManagedItemTreeNode : COItemTreeNode

@end
