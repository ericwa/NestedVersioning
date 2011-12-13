#import "COPersistentRootEditingContext+PersistentRoots.h"
#import "COPersistentRootEditingContext+Convenience.h"
#import "COMacros.h"
#import "COStoreItem.h"
#import "ETUUID.h"
#import "COStorePrivate.h"

@implementation COPersistentRootEditingContext (PersistentRoots)

- (ETUUID *)createAndInsertNewPersistentRootWithRootItem: (COStoreItemTree *)anItem
										  inItemWithUUID: (ETUUID*)aDest
{
	// FIXME: awkward translation
	NSSet *allItems = [anItem allContainedStoreItems];
	NSMutableDictionary *uuidsAndStoreItems = [NSMutableDictionary dictionary];
	for (COMutableStoreItem *item in allItems)
	{
		[uuidsAndStoreItems setObject: item forKey: [item UUID]];
	}
	
	
	ETUUID *nestedDocumentInitialVersion = [store addCommitWithParent: nil
															 metadata: nil
												   UUIDsAndStoreItems: uuidsAndStoreItems
															 rootItem: [anItem UUID]];
	assert(nestedDocumentInitialVersion != nil);
	
	
	COMutableStoreItem *i1 = [COMutableStoreItem item];
	COMutableStoreItem *i2 = [COMutableStoreItem item];
	
	[i1 setValue: @"persistentRoot"
	forAttribute: @"type"
			type: [COType stringType]];
	
	// borrow the name of the persistent root from the provided root item
	{
		NSString *name = [anItem valueForAttribute: @"name"];
		if (name == nil)
		{
			name = @"Untitled Persistent Root";
		}
		
		[i1 setValue: name
		forAttribute: @"name"
				type: [COType stringType]];		
	}
	[i1 setValue: [COPath pathWithPathComponent: [i2 UUID]]
	forAttribute: @"currentBranch"
			type: [COType pathType]];	
	[i1 setValue: S([i2 UUID])
	forAttribute: @"contents"
			type: [COType setWithPrimitiveType: [COType embeddedItemType]]];
	
	[i2 setValue: @"branch"
	forAttribute: @"type"
			type: [COType stringType]];	
	[i2 setValue: nestedDocumentInitialVersion
	forAttribute: @"currentVersion"
			type: [COType commitUUIDType]];		
	[i2 setValue: nestedDocumentInitialVersion
	forAttribute: @"head"
			type: [COType commitUUIDType]];	// limit for redo. moved on every commit.
	[i2 setValue: nestedDocumentInitialVersion
	forAttribute: @"tail"
			type: [COType commitUUIDType]];	// limit for undo. never changed.
	
	[self insertValue: [i1 UUID]
		primitiveType: [COType embeddedItemType]
	   inSetAttribute: @"contents"
			 ofObject: aDest];
		 
	[self _insertOrUpdateItems: S(i1, i2)];

	return [i1 UUID];
}



- (NSSet *) branchesOfPersistentRoot: (ETUUID *)aRoot
{
	COMutableStoreItem *root = [self _storeItemForUUID: aRoot];
	NSSet *set = [root valueForAttribute: @"contents"];
	
	assert([set isKindOfClass: [NSSet class]]);
	assert(![set isKindOfClass: [NSCountedSet class]]);
	
	return [NSSet setWithSet: set];
}
- (ETUUID *) currentBranchOfPersistentRoot: (ETUUID *)aRoot
{
	COMutableStoreItem *root = [self _storeItemForUUID: aRoot];
	COPath *aPath = [root valueForAttribute: @"currentBranch"];
	
	assert([aPath isKindOfClass: [COPath class]]);
	// FIXME: check it is a single-element path
	
	return [aPath lastPathComponent];	
}
- (void) setCurrentBranch: (ETUUID*)aBranch
		forPersistentRoot: (ETUUID*)aRoot
{
	COMutableStoreItem *root = [self _storeItemForUUID: aRoot];
	[root setValue: [COPath pathWithPathComponent: aBranch]
	  forAttribute: @"currentBranch"
			  type: [COType pathType]];
	
	[self _insertOrUpdateItems: S(root)];
}

- (ETUUID *) currentVersionForBranch: (ETUUID*)aBranch
{
	COMutableStoreItem *item = [self _storeItemForUUID: aBranch];
	return [item valueForAttribute: @"currentVersion"];
}

- (ETUUID *) headForBranch: (ETUUID*)aBranch
{
	COMutableStoreItem *item = [self _storeItemForUUID: aBranch];
	return [item valueForAttribute: @"head"];
}

- (ETUUID *) tailForBranch: (ETUUID*)aBranch
{
	COMutableStoreItem *item = [self _storeItemForUUID: aBranch];
	return [item valueForAttribute: @"tail"];
}

- (void) setCurrentVersion: (ETUUID*)aVersion
				 forBranch: (ETUUID*)aBranch
{
	COMutableStoreItem *branch = [self _storeItemForUUID: aBranch];
	
	[branch setValue: aVersion
		forAttribute: @"currentVersion"
				type: [COType commitUUIDType]];
	
	[self _insertOrUpdateItems: S(branch)];
}

/** @taskunit undo/redo */


//FIXME: This is an ugly hack
- (BOOL) isBranch: (ETUUID*)aRootOrBranch
{
	NSString *type = [[self _storeItemForUUID: aRootOrBranch] valueForAttribute: @"type"];
	assert([type isEqual: @"persistentRoot"] || 
		   [type isEqual: @"branch"]);
	return [type isEqual: @"branch"];
}

- (void) undo: (ETUUID*)aRootOrBranch
{
	if ([self isBranch: aRootOrBranch])
	{
		[self undoBranch: aRootOrBranch];
	}
	else
	{
		[self undoPersistentRoot: aRootOrBranch];
	}
}
- (void) redo: (ETUUID*)aRootOrBranch
{
	if ([self isBranch: aRootOrBranch])
	{
		[self redoBranch: aRootOrBranch];
	}
	else
	{
		[self redoPersistentRoot: aRootOrBranch];
	}	
}


- (void) undoPersistentRoot: (ETUUID*)aRoot
{
	[self undoBranch: [self currentBranchOfPersistentRoot: aRoot]];
}
- (void) redoPersistentRoot: (ETUUID*)aRoot
{
	[self redoBranch: [self currentBranchOfPersistentRoot: aRoot]];
}

- (void) undoBranch: (ETUUID*)aBranch
{
	ETUUID *currentVersion = [self currentVersionForBranch: aBranch];
	ETUUID *tail = [self tailForBranch: aBranch];
	
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
	
	[self setCurrentVersion: parent forBranch: aBranch];
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
	
	ETUUID *currentVersion = [self currentVersionForBranch: aBranch];
	ETUUID *newCurrentVersion = [self headForBranch: aBranch];
	
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
			[self setCurrentVersion: newCurrentVersion
						  forBranch: aBranch];
			return;
		}
		newCurrentVersion = parentOfNewCurrentVersion;
	}
	
	assert(0);
}


- (ETUUID *)createAndInsertNewPersistentRootByCopyingBranch: (ETUUID *)srcBranch
											 inItemWithUUID: (ETUUID *)aDest
{
	COMutableStoreItem *i1 = [COMutableStoreItem item];
	
	COMutableStoreItem *i2 = [[[self _storeItemForUUID: srcBranch] copy] autorelease];
	[i2 setUUID: [ETUUID UUID]]; // Give it a new UUID
	
	[i1 setValue: @"persistentRoot"
	forAttribute: @"type"
			type: [COType stringType]];	
	[i1 setValue: @"test document"
	forAttribute: @"name"
			type: [COType stringType]];
	[i1 setValue: [COPath pathWithPathComponent: [i2 UUID]]
	forAttribute: @"currentBranch"
			type:[COType pathType]];	
	[i1 setValue: S([i2 UUID])
	forAttribute: @"contents"
			type: [COType setWithPrimitiveType: [COType embeddedItemType]]];
	
	assert([[i2 valueForAttribute: @"type"] isEqual: @"branch"]);
	assert([[i2 typeForAttribute: @"currentVersion"] isEqual: [COType commitUUIDType]]);
	
	[self insertValue: [i1 UUID]
		primitiveType: [COType embeddedItemType]
	   inSetAttribute: @"contents"
			 ofObject: aDest];
	
	[self _insertOrUpdateItems: S(i1, i2)];
	
	return [i1 UUID];
}


- (ETUUID *) createBranchOfPersistentRoot: (ETUUID *)aRoot
{
	COMutableStoreItem *branch = [self _storeItemForUUID: [self currentBranchOfPersistentRoot: aRoot]];
	[branch setUUID: [ETUUID UUID]]; // makes it a copy.

	// Reset the limits for undo/redo
	{
		ETUUID *currentVersion = [branch valueForAttribute: @"currentVersion"];
		assert(currentVersion != nil);
		
		[branch setValue: currentVersion
			forAttribute: @"head"
					type: [COType commitUUIDType]];	// limit for redo. moved on every commit.
		[branch setValue: currentVersion
			forAttribute: @"tail"
					type: [COType commitUUIDType]];	// limit for undo. never changed.
	}
	
	[self insertValue: [branch UUID]
		primitiveType: [COType embeddedItemType]
	   inSetAttribute: @"contents"
			 ofObject: aRoot];

	[self _insertOrUpdateItems: S(branch)];
	
	return [branch UUID];
}

@end
