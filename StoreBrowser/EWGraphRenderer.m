#import "EWGraphRenderer.h"
#import "COMacros.h"
#import "COStorePrivate.h"

@interface EWGraphNode : NSObject
{
	NSRect frame;
	ETUUID *uuid;
}

@end






@implementation EWGraphRenderer

static NSUInteger visit(NSDictionary *childrenForUUID, ETUUID *currentUUID, NSUInteger currentLevel, NSMutableDictionary *levelForUUID)
{
	NSUInteger maxLevel = currentLevel;
	
	NSArray *children = [childrenForUUID objectForKey: currentUUID];
	assert(children != nil);
	for (NSUInteger i=0; i<[children count]; i++)
	{
		ETUUID *child = [children objectAtIndex: i];
		
		NSNumber *childCurrentLevel = [levelForUUID objectForKey: child];
		if (childCurrentLevel != nil)
		{
			NSLog(@"%@ already has a level %@", child, childCurrentLevel);
		}
		else
		{
			[levelForUUID setObject: [NSNumber numberWithUnsignedInteger: currentLevel + i]
							 forKey: child];
			
			if (currentLevel + i > maxLevel) maxLevel = currentLevel + i;
			
			NSUInteger visitMaxLevel = visit(childrenForUUID, child, currentLevel + i, levelForUUID);
			
			if (visitMaxLevel > maxLevel) maxLevel = visitMaxLevel;
			
		}
	}
	return maxLevel;
}

- (void) layoutGraphOfStore: (COStore*)aStore
{
	NSArray *allCommits = [aStore allCommitUUIDs];
	
	// sort by date.
	
	NSArray *allCommitsSorted = [allCommits sortedArrayUsingComparator: ^(id obj1, id obj2) {
		return [[aStore dateForCommit: obj1] compare: [aStore dateForCommit: obj2]];
	}];
	
	//
	// Now we just have to decide on the Y position of each node.
	//
	
	
	// find children for each commit (retaining sorted order)
	// this is the "display" graph
		
	NSMutableDictionary *childrenForUUID = [NSMutableDictionary dictionaryWithCapacity: [allCommits	count]];
	
	for (ETUUID *aCommit in allCommitsSorted)
	{
		[childrenForUUID setObject: [NSMutableArray array] forKey: aCommit];
	}
	for (ETUUID *aCommit in allCommitsSorted)
	{
		ETUUID *aParent = [aStore parentForCommit: aCommit];
		if (aParent != nil)
		{
			NSMutableArray *children = [childrenForUUID objectForKey: aParent];
			assert(children != nil);
			[children addObject: aCommit];
		}
	}

	
	// some nodes should have more than 1 child
	
	for (ETUUID *aCommit in allCommitsSorted)
	{
		NSLog(@"%@ children: %@", aCommit, [childrenForUUID objectForKey: aCommit]);
	}
	
	
	// find roots
	
	NSMutableArray *roots = [NSMutableArray array];
	for (ETUUID *aCommit in allCommitsSorted)
	{
		ETUUID *aParent = [aStore parentForCommit: aCommit];
		if (nil == aParent)
		{
			[roots addObject: aCommit];
		}
	}
	
	//
	// now to find the Y position, we do a DFS on the display graph.
	// the first root gets assigned level 0. when we visit a node,
	// the first child gets assigned to the current level, the second
	// child gets the current level + 1, etc. then we just visit the children
	// in order.
	//

	// FIXME: we need to do some extra work to handle the case when
	// a DAG in the forest has more than one root. this should be rare in practice,
	// because it means you merged two projects that started from scratch with no common
	// ancestor. but we should still support drawing graphs with that.

	NSMutableDictionary *levelForUUID = [NSMutableDictionary dictionary];
	NSUInteger maxLevelUsed = 0;
	for (ETUUID *root in roots)
	{
		maxLevelUsed = visit(childrenForUUID, root, 0, levelForUUID);
	}
	
	NSLog(@"graph output:");
	
	for (ETUUID *aCommit in allCommitsSorted)
	{
		NSLog(@"%d", (int)[[levelForUUID objectForKey: aCommit] intValue]);
	}
}

- (NSSize) size
{
	return size;
}
- (void) drawRect: (NSRect)aRect
{
	
}

@end
