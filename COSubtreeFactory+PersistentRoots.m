#import "COSubtreeFactory+PersistentRoots.h"
#import "COMacros.h"
#import "COItem.h"
#import "ETUUID.h"
#import "COSubtree.h"
#import "COSubtreeCopy.h"
#import "COPath.h"

@implementation COSubtreeFactory (PersistentRoots)

- (BOOL) isValidPersistentRoot: (COSubtree *)aRoot
{
	// FIXME: Implement
	return NO;
}

- (BOOL) isValidBranch: (COSubtree *)aRoot
{
	// FIXME: Implement
	return NO;
}

- (COSubtree *)persistentRootWithInitialVersion: (ETUUID *)aVersion
									displayName: (NSString *)aName
{
	NILARG_EXCEPTION_TEST(aVersion);
	NILARG_EXCEPTION_TEST(aName);
	
	COSubtree *i1 = [COSubtree subtree];
	COSubtree *i2 = [COSubtree subtree];
	
	[i1 setPrimitiveValue: @"persistentRoot"
			 forAttribute: @"type"
					 type: [COType stringType]];
	
	[i1 setPrimitiveValue: aName
			 forAttribute: @"name"
					 type: [COType stringType]];		
	
	[i1    addObject: i2
toUnorderedAttribute: @"contents"
				type: [COType setWithPrimitiveType: [COType embeddedItemType]]];
	
	// setup branch
	
	[i2 setPrimitiveValue: @"branch"
			 forAttribute: @"type"
					 type: [COType stringType]];
	
	[self setCurrentVersion: aVersion
				  forBranch: i2
			updateRedoLimit: YES
			updateUndoLimit: YES];

	[self setCurrentBranch: i2
		 forPersistentRoot: i1];	
	
	return i1;
}

- (NSSet *) branchesOfPersistentRoot: (COSubtree *)aRoot
{
	NSSet *set = [aRoot valueForAttribute: @"contents"];
	
	assert([set isKindOfClass: [NSSet class]]);
	assert(![set isKindOfClass: [NSCountedSet class]]);
	
	return [NSSet setWithSet: set];
}

- (COSubtree *) currentBranchOfPersistentRoot: (COSubtree *)aRoot
{
	COPath *aPath = [aRoot valueForAttribute: @"currentBranch"];
	
	assert([aPath isKindOfClass: [COPath class]]);
	// FIXME: check it is a single-element path
	
	ETUUID *branchUUID = [aPath lastPathComponent];	
	
	COSubtree *branch = [aRoot subtreeWithUUID: branchUUID];
	
	if (branch == nil)
	{
		[NSException raise: NSInternalInconsistencyException
					format: @"persistent root's current branch does not exist"];
	}
	
	return branch;
}

- (void) setCurrentBranch: (COSubtree *)aBranch
		forPersistentRoot: (COSubtree *)aRoot
{
	if (![self isBranch: aBranch])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"expected branch"];
	}
	
	[aRoot setPrimitiveValue: [COPath pathWithPathComponent: [aBranch UUID]]
				forAttribute: @"currentBranch"
						type: [COType pathType]];
}

- (ETUUID *) currentVersionForBranch: (COSubtree *)aBranch
{
	if (![self isBranch: aBranch])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"expected branch"];
	}
	return [aBranch valueForAttribute: @"currentVersion"];
}

- (ETUUID *) currentVersionForBranchOrPersistentRoot: (COSubtree *)aRootOrBranch
{
	if ([self isBranch: aRootOrBranch])
	{
		return [self currentVersionForBranch: aRootOrBranch];
	}
	else if ([self isPersistentRoot: aRootOrBranch])
	{
		return [self currentVersionForBranch: 
					[self currentBranchOfPersistentRoot: aRootOrBranch]];
	}

	[NSException raise: NSInvalidArgumentException
				format: @"expected persistent root or branch"];
	return nil;
}

- (ETUUID *) headForBranch: (COSubtree*)aBranch
{
	return [aBranch valueForAttribute: @"head"];
}

- (ETUUID *) tailForBranch: (COSubtree*)aBranch
{
	return [aBranch valueForAttribute: @"tail"];
}

- (void) setCurrentVersion: (ETUUID*)aVersion
				 forBranch: (COSubtree*)aBranch
		   updateRedoLimit: (BOOL)setRedoLimit
		   updateUndoLimit: (BOOL)setUndoLimit
{
	[aBranch setPrimitiveValue: aVersion
				  forAttribute: @"currentVersion"
						  type: [COType commitUUIDType]];
	if (setRedoLimit)
	{
		[aBranch setPrimitiveValue: aVersion
					  forAttribute: @"head"
							  type: [COType commitUUIDType]];
	}
	if (setUndoLimit)
	{
		[aBranch setPrimitiveValue: aVersion
					  forAttribute: @"tail"
							  type: [COType commitUUIDType]];
	}
}

- (BOOL) isBranch: (COSubtree *)anEmbeddedObject
{
	NSString *type = [anEmbeddedObject valueForAttribute: @"type"];
	return [type isEqual: @"branch"];
}

- (BOOL) isPersistentRoot: (COSubtree *)anEmbeddedObject
{
	NSString *type = [anEmbeddedObject valueForAttribute: @"type"];
	return [type isEqual: @"persistentRoot"];
}

- (COSubtree *)persistentRootByCopyingBranch: (COSubtree *)aBranch
{
	COSubtree *srcPersistentRoot = [aBranch parent];
	
	NSString *srcName = [srcPersistentRoot valueForAttribute: @"name"];
	NSString *name = [NSString stringWithFormat: @"%@ - copy of branch %@", srcName, [[aBranch UUID] stringValue]];
	
	COSubtree *i1 = [COSubtree subtree];
	
	COSubtree *i2 = [[aBranch subtreeCopyRenamingAllItems] subtree];
	
	[i1 setPrimitiveValue: @"persistentRoot"
			 forAttribute: @"type"
					 type: [COType stringType]];	
	[i1 setPrimitiveValue: name
			 forAttribute: @"name"
					 type: [COType stringType]];
	[i1    addObject: i2
toUnorderedAttribute: @"contents"
				type: [COType setWithPrimitiveType: [COType embeddedItemType]]];
	[self setCurrentBranch:i2
		 forPersistentRoot:i1];
	
	// Reset the limits for undo/redo
	{
		ETUUID *currentVersion = [i2 valueForAttribute: @"currentVersion"];
		assert(currentVersion != nil);
		
		[self setCurrentVersion: currentVersion
					  forBranch: i2
				updateRedoLimit: YES
				updateUndoLimit: YES];
	}
	
	assert([[i2 valueForAttribute: @"type"] isEqual: @"branch"]);
	assert([[i2 typeForAttribute: @"currentVersion"] isEqual: [COType commitUUIDType]]);
	
	return i1;
}

- (COSubtree *) createBranchOfPersistentRoot: (COSubtree *)aRoot
{
	COSubtree *branch = [[[self currentBranchOfPersistentRoot: aRoot] subtreeCopyRenamingAllItems] subtree];
		
	// Reset the limits for undo/redo
	{
		ETUUID *currentVersion = [branch valueForAttribute: @"currentVersion"];
		assert(currentVersion != nil);
		
		[self setCurrentVersion: currentVersion
					  forBranch: branch
				updateRedoLimit: YES
				updateUndoLimit: YES];
	}
	
	[aRoot addObject: branch
toUnorderedAttribute: @"contents"
				type: [COType setWithPrimitiveType: [COType embeddedItemType]]];
	
	return branch;
}

- (COSubtree *)createPersistentRootWithRootItem: (COSubtree *)anItem
									displayName: (NSString *)aName
										  store: (COStore *)aStore
{
	ETUUID *nestedDocumentInitialVersion = [aStore addCommitWithParent: nil
															  metadata: nil
																  tree: anItem];
	assert(nestedDocumentInitialVersion != nil);
	
	
	COSubtree *result = [[COSubtreeFactory factory] persistentRootWithInitialVersion: nestedDocumentInitialVersion
																		 displayName: aName];
	return result;
}

@end
