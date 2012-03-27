#import "COSubtreeFactory+Undo.h"
#import "COMacros.h"
#import "COItem.h"
#import "ETUUID.h"
#import "COStorePrivate.h"
#import "COSubtreeFactory.h"
#import "COSubtreeFactory+PersistentRoots.h"
#import "COSubtree.h"

@implementation COSubtreeFactory (Undo)

- (BOOL) canUndo: (COSubtree*)aRootOrBranch
		   store: (COStore *)aStore
{
	if ([[COSubtreeFactory factory] isBranch: aRootOrBranch])
	{
		return [self canUndoBranch: aRootOrBranch store: aStore];
	}
	else if ([[COSubtreeFactory factory] isPersistentRoot: aRootOrBranch])
	{
		return [self canUndoPersistentRoot: aRootOrBranch store: aStore];
	}
	return NO;
}

- (BOOL) canRedo: (COSubtree*)aRootOrBranch
		   store: (COStore *)aStore
{
	if ([[COSubtreeFactory factory] isBranch: aRootOrBranch])
	{
		return [self canRedoBranch: aRootOrBranch store: aStore];
	}
	else if ([[COSubtreeFactory factory] isPersistentRoot: aRootOrBranch])
	{
		return [self canRedoPersistentRoot: aRootOrBranch store: aStore];
	}
	return NO;
}

- (BOOL) canUndoPersistentRoot: (COSubtree*)aRoot
						 store: (COStore *)aStore
{
	return [self canUndoBranch: [[COSubtreeFactory factory] currentBranchOfPersistentRoot: aRoot]
						 store: aStore];
}
- (BOOL) canRedoPersistentRoot: (COSubtree*)aRoot
						 store: (COStore *)aStore
{
	return [self canRedoBranch: [[COSubtreeFactory factory] currentBranchOfPersistentRoot: aRoot]
						 store: aStore];
}

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

- (BOOL) shouldSkipVersion: (ETUUID *) aCommit
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
	
	ETUUID *potentialVersion = [aStore parentForCommit: currentVersion];
	
	while (1)
	{
		// FIXME: if this assertion fails, it just means the 
		// persistent root's current version and tail pointers
		// are inconsistent - it's not a fatal error.
		assert(potentialVersion != nil);  // if we are not at the tail, the current commit should have a parent
		
		if ([currentVersion isEqual: tail])
		{
			NSLog(@"Can't undo; reached tail before finding a potential version");
			return;
		}
		
		if (![self shouldSkipVersion: potentialVersion
						   forBranch: aBranch
							   store: aStore])
		{
			[[COSubtreeFactory factory] setCurrentVersion: potentialVersion
												forBranch: aBranch
										  updateRedoLimit: NO
										  updateUndoLimit: NO];
			return;
		}
		
		potentialVersion = [aStore parentForCommit: potentialVersion];
	}
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
	ETUUID *head = [[COSubtreeFactory factory] headForBranch: aBranch];
	
	assert(head != nil);
	assert(aBranch != nil);
	assert(currentVersion != nil);
	
	if ([head isEqual: currentVersion])
	{
		NSLog(@"Can't redo; already at head");
		return;
	}
	

	ETUUID *newCurrentVersion = head;
	while (1)
	{
		ETUUID *parentOfNewCurrentVersion;
		
		// Find a potential commit to redo to
		// Always allow redoing to the "head" commit, even if it is supposed
		// to be skippable. This is so undo/redo don't cause data loss.
		{
			ETUUID *temp = newCurrentVersion;
			while ([self shouldSkipVersion: temp
								 forBranch: aBranch
									 store: aStore])
			{
				temp = [aStore parentForCommit: temp];
				
				if ([temp isEqual: currentVersion])
				{
					parentOfNewCurrentVersion = currentVersion;
					break;
				}
			}
				
			if ([temp isEqual: currentVersion])
			{
				parentOfNewCurrentVersion = currentVersion;
			}			
			else
			{
				newCurrentVersion = temp;
				parentOfNewCurrentVersion = [aStore parentForCommit: newCurrentVersion];
			}
		}
					
		// FIXME: not a hard error
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

- (COSubtreeDiff *) selectiveUndoCommit: (ETUUID *) commitToUndo
							  forCommit: (ETUUID*) target
								  store: (COStore *)aStore
{
	ETUUID *commitToUndoParent = [aStore parentForCommit: commitToUndo];
	
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

- (COSubtreeDiff *) selectiveApplyCommit: (ETUUID *) commitToDo
							   forCommit: (ETUUID*) target
								   store: (COStore *)aStore
{
	ETUUID *commitToDoParent = [aStore parentForCommit: commitToDo];
	
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
