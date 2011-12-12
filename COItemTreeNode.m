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

- (COItemTreeNode *) parent
{
	return parent;
}

- (COItemTreeNode *) root
{
	COItemTreeNode *root = self;
	while ([root parent] != nil)
	{
		root = [root parent];
	}
	return root;
}

- (id) copyWithZone: (NSZone*)aZone
{
	return [self retain];
}

@end
