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

- (COPersistentRootDiff *) selectiveUndoCommit: (COUUID *) commitToUndo
									 forCommit: (COUUID*) target
										 store: (COStore *)aStore
{
	COUUID *commitToUndoParent = [aStore parentForCommit: commitToUndo];
	
	if (commitToUndoParent == nil)
	{
		NSLog(@"Selective undo failed: commit %@ has nil parent", commitToUndo);
		return nil;
	}
	
	COPersistentRootDiff *diffBackout = [COPersistentRootDiff diffCommit: commitToUndo
															  withCommit: commitToUndoParent
																   store: aStore
														sourceIdentifier: @"backout"];	
	COPersistentRootDiff *diffReapply = [COPersistentRootDiff diffCommit: commitToUndo
															  withCommit: target
																   store: aStore
														sourceIdentifier: @"reapply"];
	
	COPersistentRootDiff *merged = [diffBackout persistentRootDiffByMergingWithDiff: diffReapply];

	// FIXME: concatenate merged with diff(commitToUndo, target), to avoid having to apply merged
	// as an intermediate step. this will preserve merge conflicts, so we can return them to the caller
	
	if ([merged hasConflicts])
	{
		NSLog(@"Selective undo failed: merged diff has conflicts %@", [merged conflicts]);
		return nil;
	}
	
	COUUID *newTarget = [merged commitInStore: aStore];

	COPersistentRootDiff *diffTargetToNewTarget = [COPersistentRootDiff diffCommit: target
																		withCommit: newTarget
																			 store: aStore
																  sourceIdentifier: @""];
	assert(![diffTargetToNewTarget hasConflicts]);
	
	if (![diffTargetToNewTarget hasEdits])
	{
		NSLog(@"Selective undo failed: final diff is empty (there was nothing to undo)");
		return nil;
	}
	
	return diffTargetToNewTarget;
}

- (COPersistentRootDiff *) selectiveApplyCommit: (COUUID *) commitToDo
									  forCommit: (COUUID*) target
										  store: (COStore *)aStore
{
	COUUID *commitToDoParent = [aStore parentForCommit: commitToDo];
	
	if (commitToDoParent == nil)
	{
		NSLog(@"Selective apply failed: commit %@ has nil parent", commitToDo);
		return nil;
	}
	
	COPersistentRootDiff *diffApplyChange = [COPersistentRootDiff diffCommit: commitToDoParent
																  withCommit: commitToDo
																		store: aStore
															sourceIdentifier: @"apply-selected-change"];	
	COPersistentRootDiff *diffApplyUpToTarget = [COPersistentRootDiff diffCommit: commitToDoParent
																	  withCommit: target
																		   store: aStore	 
																sourceIdentifier: @"apply-changes-up-to-target"];
	
	COPersistentRootDiff *merged = [diffApplyChange persistentRootDiffByMergingWithDiff: diffApplyUpToTarget];
	
	if ([merged hasConflicts])
	{
		NSLog(@"Selective apply failed: merged diff has conflicts %@", [merged conflicts]);
		return nil;
	}
	
	COUUID *newTarget = [merged commitInStore: aStore];
	
	COPersistentRootDiff *diffTargetToNewTarget = [COPersistentRootDiff diffCommit: target
																		withCommit: newTarget
																			 store: aStore
																  sourceIdentifier: @""];
	
	assert(![diffTargetToNewTarget hasConflicts]);
	
	if (![diffTargetToNewTarget hasEdits])
	{
		NSLog(@"Selective apply failed: final diff is empty (there was nothing to apply)");
		return nil;
	}
	
	return diffTargetToNewTarget;
}

@end
