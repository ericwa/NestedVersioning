#import "COSubtreeDiff.h"
#import "COItemDiff.h"
#import "COMacros.h"
#import "ETUUID.h"
#import "COSubtree.h"

@implementation COSubtreeDiff

- (id) initWithRootUUID: (ETUUID*)aUUID
		itemDiffForUUID: (NSDictionary *)aDict
{
	SUPERINIT;
	ASSIGN(root, aUUID);
	ASSIGN(itemDiffForUUID, aDict);
	return self;
}

+ (COSubtreeDiff *) diffSubtree: (COSubtree *)a
					withSubtree: (COSubtree *)b
{
	NSSet *rootA_UUIDs = [a allUUIDs];
	NSSet *rootB_UUIDs = [b allUUIDs];
	
	NSMutableSet *commonUUIDs = [NSMutableSet setWithSet: rootA_UUIDs];
	[commonUUIDs intersectSet: rootB_UUIDs];
		
	NSMutableDictionary *itemDiffForUUID = [NSMutableDictionary dictionary];
	
	for (ETUUID *commonUUID in commonUUIDs)
	{
		COItem *commonItemA = [[a subtreeWithUUID: commonUUID] item];
		COItem *commonItemB = [[b subtreeWithUUID: commonUUID] item];
		
		COItemDiff *diff = [COItemDiff diffItem: commonItemA withItem: commonItemB];
		
		[itemDiffForUUID setObject: diff
							forKey: commonUUID];
	}
	
	return [[[self alloc] initWithRootUUID: [[b root] UUID]
						   itemDiffForUUID: itemDiffForUUID] autorelease];
}

- (NSString *)description
{
	NSMutableString *desc = [NSMutableString stringWithString: [super description]];
	[desc appendFormat: @" {\n"];
	for (ETUUID *uuid in itemDiffForUUID)
	{
		COItemDiff *itemdiff = [itemDiffForUUID objectForKey: uuid];
		[desc appendFormat: @"\t%@: %d edits\n", uuid, [itemdiff editCount]];
	}
 	[desc appendFormat: @"}"];
	return desc;
}

- (COSubtree *) subtreeWithDiffAppliedToSubtree: (COSubtree *)aSubtree
{
	/**
	does applying a diff to a subtree in-place even make sense?
	 
	 any pointers to within the tree might point at deallocated objects
	 after applying the diff, since any object could be deallocated.
	 hence all pointers to within the subtree must be discarded
	 
	 also, if the root changes UUID, we would have to keep the same
	 COSubtree object but change its UUID. sounds like applying 
	 diff in-place doesn't make much sense.
	 
	 */

	// Get the COItem instances to apply the diff to
	NSSet *items = [aSubtree allContainedStoreItems];
	
	// rebuild the subtree with 
	// [COSubtree subtreeWithItemSet: (NSSet*)items
	// rootUUID:]
}

@end
