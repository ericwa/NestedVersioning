#import "COSubtreeFactory+Undo.h"
#import "COMacros.h"
#import "COItem.h"
#import "ETUUID.h"
#import "COStorePrivate.h"
#import "COSubtreeFactory.h"
#import "COSubtreeFactory+PersistentRoots.h"
#import "COSubtree.h"

@implementation COSubtreeFactory (Undo)

- (void) undo: (COSubtree*)aRootOrBranch
		store: (COStore *)aStore
{
	if ([[COSubtreeFactory factory] isBranch: aRootOrBranch])
	{
		[self undoBranch: aRootOrBranch store: aStore];
	}
	else if ([[COSubtreeFactory factory] isPersistentRoot: aRootOrBranch])
	{
		[self undoPersistentRoot: aRootOrBranch store: aStore];
	}
	else
	{
		[NSException raise: NSInvalidArgumentException
					format: @"expected persistent root or branch"];
	}
}
- (void) redo: (COSubtree*)aRootOrBranch
		store: (COStore *)aStore
{
	if ([[COSubtreeFactory factory] isBranch: aRootOrBranch])
	{
		[self redoBranch: aRootOrBranch store: aStore];
	}
	else if ([[COSubtreeFactory factory] isPersistentRoot: aRootOrBranch])
	{
		[self redoPersistentRoot: aRootOrBranch store: aStore];
	}
	else
	{
		[NSException raise: NSInvalidArgumentException
					format: @"expected persistent root or branch"];
	}
}

- (void) undoPersistentRoot: (COSubtree*)aRoot
					  store: (COStore *)aStore
{
	[self undoBranch: [[COSubtreeFactory factory] currentBranchOfPersistentRoot: aRoot]
			   store: aStore];
}
- (void) redoPersistentRoot: (COSubtree*)aRoot
					  store: (COStore *)aStore
{
	[self redoBranch: [[COSubtreeFactory factory] currentBranchOfPersistentRoot: aRoot]
			   store: aStore];
}

- (void) undoBranch: (COSubtree*)aBranch
			  store: (COStore *)aStore
{
	ETUUID *currentVersion = [[COSubtreeFactory factory] currentVersionForBranch: aBranch];
	ETUUID *tail = [[COSubtreeFactory factory] tailForBranch: aBranch];
	
	assert(aBranch != nil);
	assert(currentVersion != nil);
	assert(tail != nil);
	
	if ([currentVersion isEqual: tail])
	{
		NSLog(@"Can't undo; already at tail");
		return;
	}
	
	ETUUID *parent = [aStore parentForCommit: currentVersion];
	assert(parent != nil);  // if we are not at the tail, the current commit should have a parent
	
	[[COSubtreeFactory factory] setCurrentVersion: parent
									 forBranch: aBranch
							   updateRedoLimit: NO
							   updateUndoLimit: NO];
}

- (void) redoBranch: (COSubtree*)aBranch
			  store: (COStore *)aStore
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
	
	ETUUID *currentVersion = [[COSubtreeFactory factory] currentVersionForBranch: aBranch];
	ETUUID *newCurrentVersion = [[COSubtreeFactory factory] headForBranch: aBranch];
	
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
		ETUUID *parentOfNewCurrentVersion = [aStore parentForCommit: newCurrentVersion];
		assert(parentOfNewCurrentVersion != nil);
		
		if ([parentOfNewCurrentVersion isEqual: currentVersion])
		{
			[[COSubtreeFactory factory] setCurrentVersion: newCurrentVersion
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
