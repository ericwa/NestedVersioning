#import "COPersistentRootDiff.h"
#import "COMacros.h"
#import "COPath.h"
#import "COStore.h"

@implementation COPersistentRootDiff

- (id) initWithPath: (COPath *)aRootOrBranchA
			andPath: (COPath *)aRootOrBranchB
			inStore: (COStore *)aStore
{
	SUPERINIT;
	
	return self;
}

@end
