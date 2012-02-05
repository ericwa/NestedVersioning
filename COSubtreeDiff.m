#import "COSubtreeDiff.h"
#import "COItemDiff.h"
#import "COMacros.h"
#import "ETUUID.h"
#import "COSubtree.h"

@implementation COSubtreeDiff

- (id) initWithOldRootUUID: (ETUUID*)anOldRoot
			   newRootUUID: (ETUUID*)aNewRoot
		   itemDiffForUUID: (NSDictionary *)anItemDiffForUUID
	   insertedItemForUUID: (NSDictionary *)anInsertedItemForUUID
{
	SUPERINIT;
	ASSIGN(oldRoot, anOldRoot);
	ASSIGN(newRoot, aNewRoot);
	ASSIGN(itemDiffForUUID, anItemDiffForUUID);
	ASSIGN(insertedItemForUUID, anInsertedItemForUUID);
	return self;
}

+ (COSubtreeDiff *) diffSubtree: (COSubtree *)a
					withSubtree: (COSubtree *)b
{
	NSSet *rootA_UUIDs = [a allUUIDs];
	NSSet *rootB_UUIDs = [b allUUIDs];

	
	NSMutableDictionary *itemDiffForUUID = [NSMutableDictionary dictionary];
	{
		NSMutableSet *commonUUIDs = [NSMutableSet setWithSet: rootA_UUIDs];
		[commonUUIDs intersectSet: rootB_UUIDs];
		
		for (ETUUID *aUUID in commonUUIDs)
		{
			COItem *commonItemA = [[a subtreeWithUUID: aUUID] item];
			COItem *commonItemB = [[b subtreeWithUUID: aUUID] item];
			
			COItemDiff *diff = [COItemDiff diffItem: commonItemA withItem: commonItemB];
			
			[itemDiffForUUID setObject: diff
								forKey: aUUID];
		}
	}
	
	NSMutableDictionary *insertedItemForUUID = [NSMutableDictionary dictionary];
	{
		NSMutableSet *insertedUUIDs = [NSMutableSet setWithSet: rootB_UUIDs];
		[insertedUUIDs minusSet: rootA_UUIDs];
		
		for (ETUUID *aUUID in insertedUUIDs)
		{
			[insertedItemForUUID setObject: [[b subtreeWithUUID: aUUID] item]
									forKey: aUUID];
		}		
	}
	
	return [[[self alloc] initWithOldRootUUID: [[a root] UUID]
								  newRootUUID: [[b root] UUID]
							  itemDiffForUUID: itemDiffForUUID
						  insertedItemForUUID: insertedItemForUUID] autorelease];
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

	NSSet *oldItems = [aSubtree allContainedStoreItems];
	NSMutableSet *newItems = [NSMutableSet set];
	
	if (![[[aSubtree root] UUID] isEqual: oldRoot])
	{
		NSLog(@"WARNING: diff was created from a subtree with UUID %@ and being applied to a subtree with UUID %@", oldRoot, [[aSubtree root] UUID]);
	}
	
	// Add the items from oldItems that we have a diff for
	
	for (COItem *item in oldItems)
	{
		COItemDiff *itemDiff = [itemDiffForUUID objectForKey: [item UUID]];
		if (itemDiff != nil)
		{
			COItem *newItem = [itemDiff itemWithDiffAppliedTo: item];
			[newItems addObject: newItem];
		}
	}
	
	[newItems addObjectsFromArray: [insertedItemForUUID allValues]];
	
	return [COSubtree subtreeWithItemSet: newItems
								rootUUID: newRoot];
}

@end
