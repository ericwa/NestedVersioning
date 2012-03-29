#import "COSubtreeFactory+Undo.h"
#import "COMacros.h"
#import "COItem.h"
#import "COUUID.h"
#import "COStorePrivate.h"
#import "COSubtreeFactory.h"
#import "COSubtreeFactory+PersistentRoots.h"
#import "COSubtree.h"

@implementation COSubtreeFactory (Undo)

- (BOOL) canUndoBranch: (COSubtree*)aBranch
				 store: (COStore *)aStore
{
	return ![[[COSubtreeFactory factory] currentVersionForBranch: aBranch] isEqual:
			 [[COSubtreeFactory factory] tailForBranch: aBranch]];
}

- (BOOL) canRedoBranch: (COSubtree*)aBranch
				 store: (COStore *)aStore
{ 
	return ![[[COSubtreeFactory factory] currentVersionForBranch: aBranch] isEqual:
			 [[COSubtreeFactory factory] headForBranch: aBranch]];
}

- (BOOL) shouldSkipVersion: (COUUID *) aCommit
				 forBranch: (COSubtree *) aBranch
					 store: (COStore *) aStore
{
	NSDictionary *metadata = [aStore metadataForCommit: aCommit];
	
	// FIXME: more complete..
	
	NSString *type = [metadata objectForKey: @"type"];
	if ([type isEqual: @"commitInChild"])
	{
		return YES;
	}
	
	return NO;
}

- (COUUID *) undoVersionForBranch: (COSubtree*)aBranch
						store: (COStore *)aStore
{
	COUUID *currentVersion = [[COSubtreeFactory factory] currentVersionForBranch: aBranch];
	COUUID *tail = [[COSubtreeFactory factory] tailForBranch: aBranch];
	
	assert(aBranch != nil);
	assert(currentVersion != nil);
	assert(tail != nil);
	
	if ([currentVersion isEqual: tail])
	{
		NSLog(@"Can't undo; already at tail");
		return nil;
	}
	
	COUUID *potentialVersion = [aStore parentForCommit: currentVersion];
	
	// FIXME: if this assertion fails, it just means the 
	// persistent root's current version and tail pointers
	// are inconsistent - it's not a fatal error.
	assert(potentialVersion != nil);  // if we are not at the tail, the current commit should have a parent

	return potentialVersion;
}

- (void) undoBranch: (COSubtree*)aBranch
			  store: (COStore *)aStore
{
	COUUID *version = [self undoVersionForBranch: aBranch store: aStore];
	
	if (version != nil)
	{
		[[COSubtreeFactory factory] setCurrentVersion: version
											forBranch: aBranch
									  updateRedoLimit: NO
									  updateUndoLimit: NO];
	}
}



- (COUUID *) redoVersionForBranch: (COSubtree*)aBranch
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
	
	COUUID *currentVersion = [[COSubtreeFactory factory] currentVersionForBranch: aBranch];
	COUUID *head = [[COSubtreeFactory factory] headForBranch: aBranch];
	
	assert(head != nil);
	assert(aBranch != nil);
	assert(currentVersion != nil);
	
	if ([head isEqual: currentVersion])
	{
		NSLog(@"Can't redo; already at head");
		return nil;
	}
	

	COUUID *newCurrentVersion = head;
	while (1)
	{
		COUUID *parentOfNewCurrentVersion = [aStore parentForCommit: newCurrentVersion];
	
		// FIXME: not a hard error
		assert(parentOfNewCurrentVersion != nil);
		
		if ([parentOfNewCurrentVersion isEqual: currentVersion])
		{			
			return newCurrentVersion;
		}
		
		newCurrentVersion = parentOfNewCurrentVersion;
	}
	
	assert(0);
	return nil;
}

- (void) redoBranch: (COSubtree*)aBranch
			  store: (COStore *)aStore
{
	COUUID *version = [self redoVersionForBranch: aBranch store: aStore];
	
	if (version != nil)
	{
		[[COSubtreeFactory factory] setCurrentVersion: version
											forBranch: aBranch
									  updateRedoLimit: NO
									  updateUndoLimit: NO];
	}
}

- (NSString *) undoMessageForBranch: (COSubtree*)aBranch
							  store: (COStore *)aStore
{
	COUUID *version = [self currentVersionForBranch: aBranch];
	return [aStore menuStringForCommit: version];
}

- (NSString *) redoMessageForBranch: (COSubtree*)aBranch
							  store: (COStore *)aStore
{
	COUUID *version = [self redoVersionForBranch: aBranch store: aStore];
	return [aStore menuStringForCommit: version];
}


#pragma mark selective undo and apply

- (COSubtreeDiff *) selectiveUndoCommit: (COUUID *) commitToUndo
							  forCommit: (COUUID*) target
								  store: (COStore *)aStore
{
	COUUID *commitToUndoParent = [aStore parentForCommit: commitToUndo];
	
	if (commitToUndoParent == nil)
	{
		NSLog(@"Selective undo failed: commit %@ has nil parent", commitToUndo);
		return nil;
	}
	
	COSubtree *commitToUndoSubtree = [aStore treeForCommit: commitToUndo];
	COSubtree *commitToUndoParentSubtree = [aStore treeForCommit: commitToUndoParent];
	COSubtree *targetSubtree = [aStore treeForCommit: target];
	
	COSubtreeDiff *diffBackout = [COSubtreeDiff diffSubtree: commitToUndoSubtree
												withSubtree: commitToUndoParentSubtree 
										   sourceIdentifier: @"backout"];	
	COSubtreeDiff *diffReapply = [COSubtreeDiff diffSubtree: commitToUndoSubtree
												withSubtree: targetSubtree 
										   sourceIdentifier: @"reapply"];
	
	COSubtreeDiff *merged = [diffBackout subtreeDiffByMergingWithDiff: diffReapply];
	
	if ([merged hasConflicts])
	{
		NSLog(@"Selective undo failed: merged diff has conflicts %@", [merged conflicts]);
		return nil;
	}
	
	COSubtree *newTarget = [merged subtreeWithDiffAppliedToSubtree: commitToUndoSubtree];

	COSubtreeDiff *diffTargetToNewTarget = [COSubtreeDiff diffSubtree: targetSubtree
														  withSubtree: newTarget
													 sourceIdentifier: @""];
	assert(![diffTargetToNewTarget hasConflicts]);
	
	if ([[diffTargetToNewTarget allEdits] count] == 0)
	{
		NSLog(@"Selective undo failed: final diff is empty (there was nothing to undo)");
		return nil;
	}
	
	return diffTargetToNewTarget;
}

- (COSubtreeDiff *) selectiveApplyCommit: (COUUID *) commitToDo
							   forCommit: (COUUID*) target
								   store: (COStore *)aStore
{
	COUUID *commitToDoParent = [aStore parentForCommit: commitToDo];
	
	if (commitToDoParent == nil)
	{
		NSLog(@"Selective apply failed: commit %@ has nil parent", commitToDo);
		return nil;
	}
	
	COSubtree *commitToDoSubtree = [aStore treeForCommit: commitToDo];
	COSubtree *commitToDoParentSubtree = [aStore treeForCommit: commitToDoParent];
	COSubtree *targetSubtree = [aStore treeForCommit: target];
	
	COSubtreeDiff *diffApplyChange = [COSubtreeDiff diffSubtree: commitToDoParentSubtree
													withSubtree: commitToDoSubtree 
											   sourceIdentifier: @"apply-selected-change"];	
	COSubtreeDiff *diffApplyUpToTarget = [COSubtreeDiff diffSubtree: commitToDoParentSubtree
														withSubtree: targetSubtree 
												   sourceIdentifier: @"apply-changes-up-to-target"];
	
	COSubtreeDiff *merged = [diffApplyChange subtreeDiffByMergingWithDiff: diffApplyUpToTarget];
	
	if ([merged hasConflicts])
	{
		NSLog(@"Selective apply failed: merged diff has conflicts %@", [merged conflicts]);
		return nil;
	}
	
	COSubtree *newTarget = [merged subtreeWithDiffAppliedToSubtree: commitToDoParentSubtree];
	
	COSubtreeDiff *diffTargetToNewTarget = [COSubtreeDiff diffSubtree: targetSubtree
														  withSubtree: newTarget
													 sourceIdentifier: @""];
	assert(![diffTargetToNewTarget hasConflicts]);
	
	if ([[diffTargetToNewTarget allEdits] count] == 0)
	{
		NSLog(@"Selective apply failed: final diff is empty (there was nothing to apply)");
		return nil;
	}
	
	return diffTargetToNewTarget;
}

@end
