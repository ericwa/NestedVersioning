#import "COPersistentRootEditingContext+PersistentRoots.h"
#import "COPersistentRootEditingContext+Convenience.h"
#import "COMacros.h"
#import "COItem.h"
#import "ETUUID.h"
#import "COStorePrivate.h"
#import "COItemFactory.h"
#import "COItemFactory+PersistentRoots.h"
#import "COSubtree.h"

@implementation COPersistentRootEditingContext (PersistentRoots)

- (ETUUID *)createAndInsertNewPersistentRootWithRootItem: (COSubtree *)anItem
										  inItemWithUUID: (ETUUID*)aDest
{
	ETUUID *nestedDocumentInitialVersion = [store addCommitWithParent: nil
															 metadata: nil
																 tree: anItem];
	assert(nestedDocumentInitialVersion != nil);
	

	COSubtree *result = [[COItemFactory factory] persistentRootWithInitialVersion: nestedDocumentInitialVersion
																	  displayName: @"New Persistent Root"];
	
	COSubtree *dest = [[self persistentRootTree] subtreeWithUUID: aDest];	
	[dest  addObject: result
toUnorderedAttribute: @"contents"
			    type: [COType setWithPrimitiveType: [COType embeddedItemType]]];

	return [result UUID];
}

- (BOOL) isBranch: (ETUUID *)anEmbeddedObject
{
	return [[COItemFactory factory] isBranch: [[self persistentRootTree] subtreeWithUUID: anEmbeddedObject]];
}
- (BOOL) isPersistentRoot: (ETUUID *)anEmbeddedObject
{
	return [[COItemFactory factory] isPersistentRoot: [[self persistentRootTree] subtreeWithUUID: anEmbeddedObject]];
}

- (void) undo: (ETUUID*)aRootOrBranch
{
	if ([self isBranch: aRootOrBranch])
	{
		[self undoBranch: aRootOrBranch];
	}
	else if ([self isPersistentRoot: aRootOrBranch])
	{
		[self undoPersistentRoot: aRootOrBranch];
	}
	else
	{
		assert(0);
	}
}
- (void) redo: (ETUUID*)aRootOrBranch
{
	if ([self isBranch: aRootOrBranch])
	{
		[self redoBranch: aRootOrBranch];
	}
	else if ([self isPersistentRoot: aRootOrBranch])
	{
		[self redoPersistentRoot: aRootOrBranch];
	}
	else
	{
		assert(0);
	}
}

- (void) undoPersistentRoot: (ETUUID*)aRoot
{
	COSubtree *aTree = [[self persistentRootTree] subtreeWithUUID:aRoot];
	
	[self undoBranch: [[[COItemFactory factory] currentBranchOfPersistentRoot: aTree] UUID]];
}
- (void) redoPersistentRoot: (ETUUID*)aRoot
{
	COSubtree *aTree = [[self persistentRootTree] subtreeWithUUID:aRoot];
	
	[self redoBranch: [[[COItemFactory factory] currentBranchOfPersistentRoot: aTree] UUID]];
}

- (void) undoBranch: (ETUUID*)aBranch
{
	COSubtree *branchTree = [[self persistentRootTree] subtreeWithUUID:aBranch];
	
	ETUUID *currentVersion = [[COItemFactory factory] currentVersionForBranch: branchTree];
	ETUUID *tail = [[COItemFactory factory] tailForBranch: branchTree];
	
	assert(aBranch != nil);
	assert(currentVersion != nil);
	assert(tail != nil);
	
	if ([currentVersion isEqual: tail])
	{
		NSLog(@"Can't undo; already at tail");
		return;
	}
	
	ETUUID *parent = [store parentForCommit: currentVersion];
	assert(parent != nil);  // if we are not at the tail, the current commit should have a parent
	
	[[COItemFactory factory] setCurrentVersion: parent forBranch: branchTree];
}

- (void) redoBranch: (ETUUID*)aBranch
{
	/*
	 - to redo:
	 X = "head"
	 if (X == "currentVersion") fail ("can't redo")
	 while (1) {
	   if (X.parent == "currentVersion") {
	     "currentVersion" = X;
	     finshed;
	   }
	   X = X.parent;
	 }
	 
	 **/
	
	COSubtree *branchTree = [[self persistentRootTree] subtreeWithUUID:aBranch];
	
	ETUUID *currentVersion = [[COItemFactory factory] currentVersionForBranch: branchTree];
	ETUUID *newCurrentVersion = [[COItemFactory factory] headForBranch: branchTree];
	
	assert(newCurrentVersion != nil);
	assert(aBranch != nil);
	assert(currentVersion != nil);
	
	if ([newCurrentVersion isEqual: currentVersion])
	{
		NSLog(@"Can't redo; already at head");
		return;
	}
	
	while (1)
	{
		ETUUID *parentOfNewCurrentVersion = [store parentForCommit: newCurrentVersion];
		assert(parentOfNewCurrentVersion != nil);
		
		if ([parentOfNewCurrentVersion isEqual: currentVersion])
		{
			[[COItemFactory factory] setCurrentVersion: newCurrentVersion
											 forBranch: branchTree];
			return;
		}
		newCurrentVersion = parentOfNewCurrentVersion;
	}
	
	assert(0);
}

@end
