#import "COItemTreeManager.h"

@interface COItemTreeNode (Private)

- (id)initAsFaultWithUUID: (ETUUID*)aUUID;

@end

@implementation COItemTreeManager

- (id)initWithFaultProvider: (id<COFaultProvider>)aProvider
{
	SUPERINIT;
	itemTreeNodeForUUID = [[NSMutableDictionary alloc] init];
	faultProvider = aProvider; // weak reference
	return self;
}

+ (COItemTreeManager *) treeManagerWithFaultProvider: (id<COFaultProvider>)aProvider
{
	return [[[self alloc] initWithFaultProvider: aProvider] autorelease];
}

- (void) refetchUUIDs: (NSSet*)changedUUIDs
{
	for (ETUUID *aUUID in changedUUIDs)
	{
		COManagedItemTreeNode *node = [itemTreeNodeForUUID objectForKey: aUUID];
		if (nil != node)
		{
			[node refetch]; //[node unfault];
		}
		// if node is nil, there is no instantiated COItemTreeNode for that
		// object, so there is no need to do anything.
	}
}

- (COItemTreeNode *) itemTreeNodeForUUID: (ETUUID *)aUUID
{
	COItemTreeNode *node = [itemTreeNodeForUUID objectForKey: aUUID];
	if (nil == node)
	{
		node = [[COItemTreeNode alloc] initWithUUID: aUUID];
		[itemTreeNodeForUUID setObject: node
								forKey: aUUID];
		[node release];
	}
	return node;
}

@end
