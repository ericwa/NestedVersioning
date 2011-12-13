#import "COTreeDiff.h"
#import "COStoreItemDiff.h"
#import "COMacros.h"

@implementation COTreeDiff

// FIXME: This is generally useful, not just for COTreeDiff

static void _COAllItemUUIDsInTree_implementation(ETUUID *treeRoot, id<COFaultProvider> faultProvider, NSMutableSet *result)
{
	[result addObject: treeRoot];
	
	COMutableStoreItem *item = [faultProvider itemForUUID: treeRoot];
	for (NSString *key in [item attributeNames])
	{
		COType *type = [item typeForAttribute: key];
		if ([[type primitiveType] isEqual: [COType embeddedItemType]])
		{		
			for (ETUUID *embedded in [item allObjectsForAttribute: key])
			{
				_COAllItemUUIDsInTree_implementation(treeRoot, faultProvider, result);
			}
		}
	}
}

static NSSet *COAllItemUUIDsInTree(ETUUID *treeRoot, id<COFaultProvider> faultProvider)
{
	NSMutableSet *result = [NSMutableSet set];
	_COAllItemUUIDsInTree_implementation(treeRoot, faultProvider, result);
	return result;
}

- (id) initWithRootUUID: (ETUUID*)aUUID
		itemDiffForUUID: (NSDictionary *)aDict
{
	SUPERINIT;
	ASSIGN(root, aUUID);
	ASSIGN(itemDiffForUUID, aDict);
	return self;
}

+ (COTreeDiff *) diffRootItem: (ETUUID*)rootA
				 withRootItem: (ETUUID*)rootB
			  inFaultProvider: (id<COFaultProvider>)providerA
			withFaultProvider: (id<COFaultProvider>)providerB
{
	NSSet *rootA_UUIDs = COAllItemUUIDsInTree(rootA, providerA);
	NSSet *rootB_UUIDs = COAllItemUUIDsInTree(rootB, providerB);
	
	NSMutableSet *commonUUIDs = [NSMutableSet setWithSet: rootA_UUIDs];
	[commonUUIDs intersectSet: rootB_UUIDs];
	
	// ok.. move detection.
	
	NSMutableDictionary *itemDiffForUUID = [NSMutableDictionary dictionary];
	
	for (ETUUID *commonUUID in commonUUIDs)
	{
		COMutableStoreItem *commonItemA = [providerA itemForUUID: commonUUID];
		COMutableStoreItem *commonItemB = [providerB itemForUUID: commonUUID];
		
		COStoreItemDiff *diff = [COStoreItemDiff diffItem: commonItemA withItem: commonItemB];
		
		[itemDiffForUUID setObject: diff
							forKey: commonUUID];
	}
	
	return [[[self alloc] initWithRootUUID: rootB
						   itemDiffForUUID: itemDiffForUUID] autorelease];
}

@end
