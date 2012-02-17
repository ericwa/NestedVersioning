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

@end
