#import "COPersistentRootEditingContext+PersistentRoots.h"
#import "COPersistentRootEditingContext+Convenience.h"
#import "COMacros.h"
#import "COItem.h"
#import "ETUUID.h"
#import "COStorePrivate.h"

@implementation COPersistentRootEditingContext (PersistentRoots)

- (ETUUID *)createAndInsertNewPersistentRootWithRootItem: (COItemTreeNode *)anItem
										  inItemWithUUID: (ETUUID*)aDest
{
	// FIXME: awkward translation
	NSSet *allItems = [anItem allContainedStoreItems];
	NSMutableDictionary *uuidsAndStoreItems = [NSMutableDictionary dictionary];
	for (COMutableItem *item in allItems)
	{
		[uuidsAndStoreItems setObject: item forKey: [item UUID]];
	}
	
	
	ETUUID *nestedDocumentInitialVersion = [store addCommitWithParent: nil
															 metadata: nil
												   UUIDsAndStoreItems: uuidsAndStoreItems
															 rootItem: [anItem UUID]];
	assert(nestedDocumentInitialVersion != nil);
	
	
	COMutableItem *i1 = [COMutableItem item];
	COMutableItem *i2 = [COMutableItem item];
	
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
	COMutableItem *root = [self _storeItemForUUID: aRoot];
	NSSet *set = [root valueForAttribute: @"contents"];
	
	assert([set isKindOfClass: [NSSet class]]);
	assert(![set isKindOfClass: [NSCountedSet class]]);
	
	return [NSSet setWithSet: set];
}
- (ETUUID *) currentBranchOfPersistentRoot: (ETUUID *)aRoot
{
	COMutableItem *root = [self _storeItemForUUID: aRoot];
	COPath *aPath = [root valueForAttribute: @"currentBranch"];
	
	assert([aPath isKindOfClass: [COPath class]]);
	// FIXME: check it is a single-element path
	
	return [aPath lastPathComponent];	
}
- (void) setCurrentBranch: (ETUUID*)aBranch
		forPersistentRoot: (ETUUID*)aRoot
{
	COMutableItem *root = [self _storeItemForUUID: aRoot];
	[root setValue: [COPath pathWithPathComponent: aBranch]
	  forAttribute: @"currentBranch"
			  type: [COType pathType]];
	
	[self _insertOrUpdateItems: S(root)];
}

- (ETUUID *) currentVersionForBranch: (ETUUID*)aBranch
{
	assert([self isBranch: aBranch]);
	COMutableItem *item = [self _storeItemForUUID: aBranch];
	return [item valueForAttribute: @"currentVersion"];
}

- (ETUUID *) currentVersionForBranchOrPersistentRoot: (ETUUID*)aRootOrBranch;
{
	if ([self isBranch: aRootOrBranch])
	{
		return [self currentVersionForBranch: aRootOrBranch];
	}
	else if ([self isPersistentRoot: aRootOrBranch])
	{
		ETUUID *currentBranch = [self currentBranchOfPersistentRoot: aRootOrBranch];
		return [self currentVersionForBranch: currentBranch];
	}
	else
	{
		assert(0);
	}
}

- (ETUUID *) headForBranch: (ETUUID*)aBranch
{
	COMutableItem *item = [self _storeItemForUUID: aBranch];
	return [item valueForAttribute: @"head"];
}

- (ETUUID *) tailForBranch: (ETUUID*)aBranch
{
	COMutableItem *item = [self _storeItemForUUID: aBranch];
	return [item valueForAttribute: @"tail"];
}

- (void) setCurrentVersion: (ETUUID*)aVersion
				 forBranch: (ETUUID*)aBranch
{
	COMutableItem *branch = [self _storeItemForUUID: aBranch];
	
	[branch setValue: aVersion
		forAttribute: @"currentVersion"
				type: [COType commitUUIDType]];
	
	[self _insertOrUpdateItems: S(branch)];
}

/** @taskunit undo/redo */

- (BOOL) isBranch: (ETUUID*)anEmbeddedObject
{
	NSString *type = [[self _storeItemForUUID: anEmbeddedObject] valueForAttribute: @"type"];
	return [type isEqual: @"branch"];
}

- (BOOL) isPersistentRoot: (ETUUID*)anEmbeddedObject
{
	NSString *type = [[self _storeItemForUUID: anEmbeddedObject] valueForAttribute: @"type"];
	return [type isEqual: @"persistentRoot"];
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
										   ofPersistentRoot: (ETUUID *)srcPersistentRoot
											 inItemWithUUID: (ETUUID *)aDest
{
	assert([[self branchesOfPersistentRoot: srcPersistentRoot] containsObject: srcBranch]);
	
	NSString *srcName = [[self _storeItemForUUID: srcPersistentRoot] valueForAttribute: @"name"];
	NSString *name = [NSString stringWithFormat: @"%@ - copy of branch %@", srcName, [srcBranch stringValue]];
	
	COMutableItem *i1 = [COMutableItem item];
	
	COMutableItem *i2 = [[[self _storeItemForUUID: srcBranch] copy] autorelease];
	[i2 setUUID: [ETUUID UUID]]; // Give it a new UUID
	
	[i1 setValue: @"persistentRoot"
	forAttribute: @"type"
			type: [COType stringType]];	
	[i1 setValue: name
	forAttribute: @"name"
			type: [COType stringType]];
	[i1 setValue: [COPath pathWithPathComponent: [i2 UUID]]
	forAttribute: @"currentBranch"
			type:[COType pathType]];	
	[i1 setValue: S([i2 UUID])
	forAttribute: @"contents"
			type: [COType setWithPrimitiveType: [COType embeddedItemType]]];
	
	// Reset the limits for undo/redo
	{
		ETUUID *currentVersion = [i2 valueForAttribute: @"currentVersion"];
		assert(currentVersion != nil);
		
		[i2 setValue: currentVersion
		forAttribute: @"head"
				type: [COType commitUUIDType]];	// limit for redo. moved on every commit.
		[i2 setValue: currentVersion
		forAttribute: @"tail"
				type: [COType commitUUIDType]];	// limit for undo. never changed.
	}
	
	
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
	COMutableItem *branch = [self _storeItemForUUID: [self currentBranchOfPersistentRoot: aRoot]];
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
