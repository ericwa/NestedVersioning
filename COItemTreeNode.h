#import <Foundation/Foundation.h>
#import "COFaultProvider.h"

/**
 * Tree node that gets its data from a fault provider. when the fault provider
 * changes, it needs to re-fetch the state.
 */
@interface COItemTreeNode : NSObject
{

}


/** @taskunit private */

- (void) refetch;

@end
