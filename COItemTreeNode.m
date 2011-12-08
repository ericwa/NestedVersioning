#import "COItemTreeNode.h"
#import "COMacros.h"

@implementation COItemTreeNode

- (void)dealloc
{
	[valueForAttribute release];
	[typeForAttribute release];
	[super dealloc];
}

/**
 * Called by COItemTreeManager
 */
- (void) refetch
{
	
}

@end
