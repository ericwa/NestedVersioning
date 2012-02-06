#import "COPersistentRootEditingContext+PersistentRoots.h"
#import "COMacros.h"
#import "COItem.h"
#import "ETUUID.h"
#import "COStorePrivate.h"
#import "COItemFactory.h"
#import "COItemFactory+PersistentRoots.h"
#import "COSubtree.h"

@implementation COPersistentRootEditingContext (PersistentRoots)

- (COSubtree *)createPersistentRootWithRootItem: (COSubtree *)anItem
									displayName: (NSString *)aName
{
	ETUUID *nestedDocumentInitialVersion = [store addCommitWithParent: nil
															 metadata: nil
																 tree: anItem];
	assert(nestedDocumentInitialVersion != nil);
	

	COSubtree *result = [[COItemFactory factory] persistentRootWithInitialVersion: nestedDocumentInitialVersion
																	  displayName: @"New Persistent Root"];
	return result;
}

- (void) undo: (COSubtree*)aRootOrBranch
{
	if ([[COItemFactory factory] isBranch: aRootOrBranch])
	{
		[self undoBranch: aRootOrBranch];
	}
	else if ([[COItemFactory factory] isPersistentRoot: aRootOrBranch])
	{
		[self undoPersistentRoot: aRootOrBranch];
	}
	else
	{
		[NSException raise: NSInvalidArgumentException
					format: @"expected persistent root or branch"];
	}
}
- (void) redo: (COSubtree*)aRootOrBranch
{
	if ([[COItemFactory factory] isBranch: aRootOrBranch])
	{
		[self redoBranch: aRootOrBranch];
	}
	else if ([[COItemFactory factory] isPersistentRoot: aRootOrBranch])
	{
		[self redoPersistentRoot: aRootOrBranch];
	}
	else
	{
		[NSException raise: NSInvalidArgumentException
					format: @"expected persistent root or branch"];
	}
}

- (void) undoPersistentRoot: (COSubtree*)aRoot
{
	[self undoBranch: [[COItemFactory factory] currentBranchOfPersistentRoot: aRoot]];
}
- (void) redoPersistentRoot: (COSubtree*)aRoot
{
	[self redoBranch: [[COItemFactory factory] currentBranchOfPersistentRoot: aRoot]];
}

- (void) undoBranch: (COSubtree*)aBranch
{
	ETUUID *currentVersion = [[COItemFactory factory] currentVersionForBranch: aBranch];
	ETUUID *tail = [[COItemFactory factory] tailForBranch: aBranch];
	
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
	
	[[COItemFactory factory] setCurrentVersion: parent
									 forBranch: aBranch
							   updateRedoLimit: NO
							   updateUndoLimit: NO];
}

- (void) redoBranch: (COSubtree*)aBranch
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
	
	ETUUID *currentVersion = [[COItemFactory factory] currentVersionForBranch: aBranch];
	ETUUID *newCurrentVersion = [[COItemFactory factory] headForBranch: aBranch];
	
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
											 forBranch: aBranch			 
									   updateRedoLimit: NO
									   updateUndoLimit: NO];
			return;
		}
		newCurrentVersion = parentOfNewCurrentVersion;
	}
	
	assert(0);
}

@end
