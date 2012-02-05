#import "COPersistentRootEditingContext+Convenience.h"
#import "COMacros.h"
#import "COItem.h"
#import "ETUUID.h"
#import "COType.h"

@implementation COPersistentRootEditingContext (Convenience)

// FIXME: remove
- (void) insertValue: (id)aValue
	   primitiveType: (COType *)aPrimitiveType
	  inSetAttribute: (NSString*)anAttribute
			ofObject: (ETUUID*)aDest
{
	COSubtree *destTree = [[self persistentRootTree] subtreeWithUUID: aDest];
	[destTree addObject: aValue
   toUnorderedAttribute: anAttribute
				   type: [COType setWithPrimitiveType: aPrimitiveType]];
}

// FIXME: remove
- (ETUUID *) insertTree: (COSubtree*)aTree
		inContainer: (ETUUID*)aContainer
{
	COSubtree *destTree = [[self persistentRootTree] subtreeWithUUID: aContainer];
	[destTree addObject: aTree
   toUnorderedAttribute: @"contents"
				   type: [COType setWithPrimitiveType: [COType embeddedItemType]]];
	return [aTree UUID];
}

@end