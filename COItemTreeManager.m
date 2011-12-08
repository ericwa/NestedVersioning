#import "COItemTreeManager.h"

@implementation COItemTreeManager

- (void) refetchUUIDs: (NSSet*)changedUUIDs
{
	for (ETUUID *aUUID in changedUUIDs)
	{
		COItemTreeNode *node = [itemTreeNodeForUUID objectForKey: aUUID];
		if (nil != node)
		{
			[node refetch];
		}
		// if node is nil, there is no instantiated COItemTreeNode for that
		// object, so there is no need to do anything.
	}
}

@end
