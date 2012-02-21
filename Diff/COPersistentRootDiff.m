#import "COPersistentRootDiff.h"
#import "COMacros.h"
#import "COPath.h"
#import "COStore.h"
#import "COPersistentRootEditingContext.h"
#import "COSubtreeFactory+PersistentRoots.h"

@implementation COPersistentRootDiff

+ (COSubtree *) persistentRootOrBranchForPath: (COPath *)aPath inStore: (COStore *)aStore
{
	COPersistentRootEditingContext *ctx = 
	[COPersistentRootEditingContext editingContextForEditingPath: [aPath pathByDeletingLastPathComponent]
														 inStore: aStore];
	
	return [[ctx persistentRootTree] subtreeWithUUID: [aPath lastPathComponent]];
	
}

- (id) initWithPath: (COPath *)aRootOrBranchA
			andPath: (COPath *)aRootOrBranchB
			inStore: (COStore *)aStore
{
	SUPERINIT;
	
	COSubtree *subtreeA = [[self class] persistentRootOrBranchForPath: aRootOrBranchA inStore: aStore];
	COSubtree *subtreeB = [[self class] persistentRootOrBranchForPath: aRootOrBranchB inStore: aStore];
	
	
	if ([[COSubtreeFactory factory] isBranch: subtreeA] && [[COSubtreeFactory factory] isBranch: subtreeB])
	{
		// branch vs branch
		
	}
	else if ([[COSubtreeFactory factory] isPersistentRoot: subtreeA] && [[COSubtreeFactory factory] isPersistentRoot: subtreeB])
	{
		// persistent root vs persistent root
		
	}
	else
	{
		[NSException raise: NSInvalidArgumentException
					format: @"Only branch/branch or proot/proot diff is handled for now."];
	}
	
	
	return self;
}

@end
