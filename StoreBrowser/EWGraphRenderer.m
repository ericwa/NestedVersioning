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

static void visit(NSDictionary *childrenForUUID, ETUUID *currentUUID, NSUInteger currentLevel, NSMutableDictionary *levelForUUID)
{
	NSLog(@"visiting %@", currentUUID);
	
	NSNumber *currentSavedLevel = [levelForUUID objectForKey: currentUUID];
	if (currentSavedLevel != nil)
	{
		NSLog(@"%@ already has a level %@", currentUUID, currentSavedLevel);
		return;
	}
	else
	{
		[levelForUUID setObject: [NSNumber numberWithUnsignedInteger: currentLevel]
						 forKey: currentUUID];
	}
	
	
	NSArray *children = [childrenForUUID objectForKey: currentUUID];
	assert(children != nil);
	for (NSUInteger i=0; i<[children count]; i++)
	{
		ETUUID *child = [children objectAtIndex: i];
		
		visit(childrenForUUID, child, currentLevel + i, levelForUUID);
	}
}

- (void) layoutGraphOfStore: (COStore*)aStore
{
	NSArray *allCommits = [aStore allCommitUUIDs];
	
	// sort by date.
	
	ASSIGN(allCommitsSorted, [allCommits sortedArrayUsingComparator: ^(id obj1, id obj2) {
		return [[aStore dateForCommit: obj1] compare: [aStore dateForCommit: obj2]];
	}]);
	
	//
	// Now we just have to decide on the Y position of each node.
	//
	
	
	// find children for each commit (retaining sorted order)
	// this is the "display" graph
		
	ASSIGN(childrenForUUID, [NSMutableDictionary dictionaryWithCapacity: [allCommits	count]]);
	
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

	ASSIGN(levelForUUID, [NSMutableDictionary dictionary]);

	for (ETUUID *root in roots)
	{
		 visit(childrenForUUID, root, 0, levelForUUID);
	}
	
	NSLog(@"graph output:");
	
	maxLevelUsed = 0;
	for (ETUUID *aCommit in allCommitsSorted)
	{
		NSUInteger level = [[levelForUUID objectForKey: aCommit] intValue];
		
		if (level > maxLevelUsed)
			maxLevelUsed = level;
		
		NSLog(@"%d", (int)level);
	}
}

- (NSSize) size
{
	NSSize s = NSMakeSize(64 * [allCommitsSorted count], 64 * (maxLevelUsed + 1));
	
	return s;
}

- (NSRect) rectForCommit: (ETUUID*)aCommit
{
	NSNumber *rowObj = [levelForUUID objectForKey: aCommit];
	assert(rowObj != nil);
	NSUInteger row = [rowObj integerValue];
	NSUInteger col = [allCommitsSorted indexOfObject: aCommit];
	
	NSRect cellRect = NSMakeRect(col * 64, row * 64, 64, 64);
	
	return cellRect;
}

static void EWDrawHorizontalArrowOfLength(CGFloat length)
{
	const CGFloat cap = 3;
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint: NSMakePoint(0, 0)];
	[path lineToPoint: NSMakePoint(length - cap, 0)];
	[path stroke];
	
	[path removeAllPoints];
	[path moveToPoint: NSMakePoint(length - cap, cap / 2.0)];
	[path lineToPoint: NSMakePoint(length - cap, cap / -2.0)];
	[path lineToPoint: NSMakePoint(length, 0)];
	[path lineToPoint: NSMakePoint(length - cap, cap / 2.0)];
	[path fill];
}

- (void) draw
{
	for (NSUInteger col = 0; col < [allCommitsSorted count]; col++)
	{
		ETUUID *commit = [allCommitsSorted objectAtIndex: col];		
		
		[[NSColor blackColor] setStroke];
		
		NSRect r = [self rectForCommit: commit];
		[[NSBezierPath bezierPathWithOvalInRect: NSInsetRect(r, 8, 8)] stroke];
		
		for (ETUUID *child in [childrenForUUID objectForKey: commit])
		{
			NSPoint p1 = r.origin;
			NSPoint p2 = [self rectForCommit: child].origin;
			
			p1 = NSMakePoint(p1.x + 56, p1.y + 32);
			p2 = NSMakePoint(p2.x + 8, p2.y + 32);
			
			/*assert(!(p2.x-p1.x == 0 && p2.y-p1.y == 0));
			
			[NSGraphicsContext saveGraphicsState];
			
			NSAffineTransform *xform = [NSAffineTransform transform];
			[xform translateXBy:p1.x yBy:p1.y];
			[xform rotateByRadians: atan2(p2.x-p1.x, p2.y-p1.y)];
			[xform concat];
			
			CGFloat hypotenuse = sqrt(pow(p2.x-p1.x, 2) + pow(p2.y-p1.y, 2));
			EWDrawHorizontalArrowOfLength(hypotenuse);
			
			[NSGraphicsContext restoreGraphicsState];*/
			
			NSBezierPath *p = [NSBezierPath bezierPath];
			[p moveToPoint: p1];
			[p lineToPoint: p2];
			[p stroke];
			
		}
	}
}

@end
