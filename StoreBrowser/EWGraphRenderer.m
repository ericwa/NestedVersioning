#import "EWGraphRenderer.h"
#import "COMacros.h"
#import "COStorePrivate.h"


@implementation EWGraphRenderer

static NSInteger visit(NSDictionary *childrenForUUID, ETUUID *currentUUID, NSInteger currentLevel, NSMutableDictionary *levelForUUID)
{
	//NSLog(@"visiting %@", currentUUID);
	
	NSNumber *currentSavedLevel = [levelForUUID objectForKey: currentUUID];
	if (currentSavedLevel != nil)
	{
		//NSLog(@"%@ already has a level %@", currentUUID, currentSavedLevel);
		return 0;
	}
	else
	{
		[levelForUUID setObject: [NSNumber numberWithInteger: currentLevel]
						 forKey: currentUUID];
	}
	
	
	NSArray *children = [childrenForUUID objectForKey: currentUUID];
	assert(children != nil);
	
	NSInteger maxLevelUsed = currentLevel - 1;
	for (ETUUID *child in children)
	{
		NSInteger childMax = 
			visit(childrenForUUID, child, maxLevelUsed + 1, levelForUUID);
		
		if (childMax > maxLevelUsed)
		{
			maxLevelUsed = childMax;
		}
	}
	return MAX(currentLevel, maxLevelUsed);
}

- (id) initWithStore: (COStore*)aStore
{
	SUPERINIT;
	ASSIGN(store, aStore);
	return self;
}

- (void) dealloc
{
	[allCommitsSorted release];
	[childrenForUUID release];
	[levelForUUID release];
	[store release];
	[super dealloc];
}

- (void) layoutGraph
{
	ASSIGN(allCommitsSorted, [NSMutableArray arrayWithArray: [store allCommitUUIDs]]);
	
	//
	// Now we just have to decide on the Y position of each node.
	//
	
	// find children for each commit (retaining sorted order)
	// this is the "display" graph
		
	ASSIGN(childrenForUUID, [NSMutableDictionary dictionaryWithCapacity: [allCommitsSorted count]]);
	
	for (ETUUID *aCommit in allCommitsSorted)
	{
		[childrenForUUID setObject: [NSMutableArray array] forKey: aCommit];
	}
	for (ETUUID *aCommit in allCommitsSorted)
	{
		ETUUID *aParent = [store parentForCommit: aCommit];
		if (aParent != nil)
		{
			NSMutableArray *children = [childrenForUUID objectForKey: aParent];
			assert(children != nil);
			[children addObject: aCommit];
		}
	}

	// remove commits which have no children/parents
	
	for (ETUUID *aCommit in [NSArray arrayWithArray: allCommitsSorted])
	{
		if ([[childrenForUUID objectForKey: aCommit] count] == 0 &&
			[store parentForCommit: aCommit] == nil)
		{
			//NSLog(@"removed %@ because it had no parents/children (%d)", 
			//	  aCommit, (int)[allCommitsSorted indexOfObject: aCommit]);
			[allCommitsSorted removeObject: aCommit];

		}
	}
	
	
	// some nodes should have more than 1 child
	
	for (ETUUID *aCommit in allCommitsSorted)
	{
		//NSLog(@"%@ children: %@", aCommit, [childrenForUUID objectForKey: aCommit]);
	}
	
	
	// find roots
	
	NSMutableArray *roots = [NSMutableArray array];
	for (ETUUID *aCommit in allCommitsSorted)
	{
		ETUUID *aParent = [store parentForCommit: aCommit];
		if (nil == aParent)
		{
			[roots addObject: aCommit];
		}
	}
	
	//NSLog(@"Graph drawing:: %d roots", (int)[roots count]);
	
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

	NSInteger maxLevel = 0;
	for (ETUUID *root in roots)
	{
		//NSLog(@"Starting root %@ at %d", root, (int)maxLevel);
		maxLevel = visit(childrenForUUID, root, maxLevel, levelForUUID) + 1;
	}
	
	//NSLog(@"graph output:");
	
	maxLevelUsed = 0;
	for (ETUUID *aCommit in allCommitsSorted)
	{
		NSInteger level = [[levelForUUID objectForKey: aCommit] integerValue];
		
		if (level > maxLevelUsed)
			maxLevelUsed = level;
		
		//NSLog(@"%d", (int)level);
	}

	// sanity check: Every object's parent must appear to its left.
	
	{
		NSInteger i;
		for (i=0; i<[allCommitsSorted count]; i++)
		{
			ETUUID *aCommit = [allCommitsSorted objectAtIndex: i];
			ETUUID *aCommitParent = [store parentForCommit: aCommit];
			
			if (aCommitParent != nil)
			{
				NSUInteger j = [allCommitsSorted indexOfObject: aCommitParent];
				assert(j != NSNotFound);
				assert(j < i);
			}
		}
	}
}

- (NSSize) size
{
	NSSize s = NSMakeSize(32 * [allCommitsSorted count], 32 * (maxLevelUsed + 1));
	
	return s;
}

- (NSRect) rectForCommit: (ETUUID*)aCommit
{
	NSNumber *rowObj = [levelForUUID objectForKey: aCommit];
	assert(rowObj != nil);
	NSUInteger row = [rowObj integerValue];
	NSUInteger col = [allCommitsSorted indexOfObject: aCommit];
	
	NSRect cellRect = NSMakeRect(col * 32, row * 32, 16, 16);
	
	return cellRect;
}

static void EWDrawHorizontalArrowOfLength(CGFloat length)
{
	const CGFloat cap = 8;
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint: NSMakePoint(0, 0)];
	[path lineToPoint: NSMakePoint(length - cap, 0)];
	[path stroke];
	
	[path removeAllPoints];
	[path moveToPoint: NSMakePoint(length - cap, cap / 2.0)];
	[path lineToPoint: NSMakePoint(length - cap, cap / -2.0)];
	[path lineToPoint: NSMakePoint(length, 0)];
	[path closePath];
	[path fill];
}

#define EWRandFloat() (rand()/(CGFloat)(RAND_MAX))

static void EWDrawArrowFromTo(NSPoint p1, NSPoint p2)
{	
	[NSGraphicsContext saveGraphicsState];
	
	//[[NSColor colorWithCalibratedHue:EWRandFloat() saturation:1 brightness:0.5 alpha:0.5] set];
	
	NSAffineTransform *xform = [NSAffineTransform transform];
	[xform translateXBy:p1.x yBy:p1.y];
	[xform rotateByRadians: atan2(p2.y-p1.y, p2.x-p1.x)];
	[xform concat];

	EWDrawHorizontalArrowOfLength(sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2)));
	
	[NSGraphicsContext restoreGraphicsState];
}

- (void) drawWithHighlightedCommit: (ETUUID*)aCommit
{
	for (NSUInteger col = 0; col < [allCommitsSorted count]; col++)
	{
		ETUUID *commit = [allCommitsSorted objectAtIndex: col];		
		
		NSRect r = [self rectForCommit: commit];
		NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect: r];
		
		if ([commit isEqual: aCommit])
		{
			[[NSColor purpleColor] set];
			[circle setLineWidth: 3];
			[circle stroke];
		}
		else
		{
			[[NSColor blackColor] set];
			[circle stroke];
		}
		
		[[NSColor blackColor] set];
		for (ETUUID *child in [childrenForUUID objectForKey: commit])
		{
			NSRect r2 = [self rectForCommit: child];
			
			NSPoint p = NSMakePoint(r.origin.x + r.size.width/2, r.origin.y + r.size.height/2);
			NSPoint p2 = NSMakePoint(r2.origin.x + r2.size.width/2, r2.origin.y + r2.size.height/2);
			
			p.x += 8;
			p2.x -= 8;
			
			EWDrawArrowFromTo(p, p2);
		}
	}
}

@end
