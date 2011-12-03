#import "COPersistentRootEditingContext+PersistentRoots.h"
#import "Common.h"
#import "COStoreItem.h"
#import "ETUUID.h"

@implementation COPersistentRootEditingContext (PersistentRoots)

- (ETUUID *)createAndInsertNewPersistentRootWithRootItem: (COStoreItem *)anItem
										  inItemWithUUID: (ETUUID*)aDest
{
	ETUUID *nestedDocumentInitialVersion = [store addCommitWithParent: nil
															 metadata: nil
												   UUIDsAndStoreItems: D(anItem, [anItem UUID])
															 rootItem: [anItem UUID]];
	assert(nestedDocumentInitialVersion != nil);
	
	
	COStoreItem *i1 = [COStoreItem item];
	COStoreItem *i2 = [COStoreItem item];
	
	[i1 setValue: @"persistentRoot"
	forAttribute: @"type"
			type: COPrimitiveType(kCOPrimitiveTypeString)];	
	[i1 setValue: @"test document"
	forAttribute: @"name"
			type: COPrimitiveType(kCOPrimitiveTypeString)];
	[i1 setValue: [COPath pathWithPathComponent: [i2 UUID]]
	forAttribute: @"currentBranch"
			type: COPrimitiveType(kCOPrimitiveTypePath)];	
	[i1 setValue: S([i2 UUID])
	forAttribute: @"contents"
			type: COSetContainerType(kCOPrimitiveTypeEmbeddedItem)];
	
	[i2 setValue: @"branch"
	forAttribute: @"type"
			type: COPrimitiveType(kCOPrimitiveTypeString)];	
	[i2 setValue: nestedDocumentInitialVersion
	forAttribute: @"tracking"
			type: COPrimitiveType(kCOPrimitiveTypeCommitUUID)];		
	[i2 setValue: nestedDocumentInitialVersion
	forAttribute: @"tip"
			type: COPrimitiveType(kCOPrimitiveTypeCommitUUID)];	
	
	// insert
	
	COStoreItem *destItem = [self _storeItemForUUID: aDest];
	assert(destItem != nil);
	
	// FIXME: Factor out!
	
	NSSet *destContents = [destItem valueForAttribute: @"contents"];
	if (destContents == nil)
	{
		destContents = S([i1 UUID]);
	}
	else
	{
		assert([destContents isKindOfClass: [NSSet class]]);
		destContents = [destContents setByAddingObject: [i1 UUID]];
	}
	
	[destItem setValue: destContents
		  forAttribute: @"contents"
				  type: COSetContainerType(kCOPrimitiveTypeEmbeddedItem)];
	
	[self _insertOrUpdateItems: S(i1, i2, destItem)];

	return [i1 UUID];
}



- (NSSet *) branchesOfPersistentRoot: (ETUUID *)aRoot
{
	COStoreItem *root = [self _storeItemForUUID: aRoot];
	NSSet *set = [root valueForAttribute: @"contents"];
	
	assert([set isKindOfClass: [NSSet class]]);
	assert(![set isKindOfClass: [NSCountedSet class]]);
	
	return [NSSet setWithSet: set];
}
- (ETUUID *) currentBranchOfPersistentRoot: (ETUUID *)aRoot
{
	COStoreItem *root = [self _storeItemForUUID: aRoot];
	COPath *path = [root valueForAttribute: @"currentBranch"];
	
	assert([path isKindOfClass: [COPath class]]);
	// FIXME: check it is a single-element path
	
	return [path lastPathComponent];	
}
- (void) setCurrentBranch: (ETUUID*)aBranch
		forPersistentRoot: (ETUUID*)aRoot
{
	COStoreItem *root = [self _storeItemForUUID: aRoot];
	[root setValue: [COPath pathWithPathComponent: aBranch]
	  forAttribute: @"currentBranch"
			  type: COPrimitiveType(kCOPrimitiveTypePath)];
	
	[self _insertOrUpdateItems: S(root)];
}


- (void) setTrackVersion: (ETUUID*)aVersion
			   forBranch: (ETUUID*)aBranch
{
	COStoreItem *branch = [self _storeItemForUUID: aBranch];
	
	[branch setValue: aVersion
		forAttribute: @"tracking"
				type: COPrimitiveType(kCOPrimitiveTypeCommitUUID)];
	
	[self _insertOrUpdateItems: S(branch)];
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
	/*
	 - to undo:
	 a) look up the version that "tracking" points to
	 b) get its parent (if it has none, can't undo)
	 c) set "tracking" to the parent, without modifying tip
	 
	 */	
	assert(0);
}
- (void) redoBranch: (ETUUID*)aBranch
{
	/*
	 - to redo:
	 X = "tip"
	 if (X == "tracking") fail ("can't redo")
	 while (1) {
	 if (X.parent == "tracking") {
	 "tracking" = X;
	 finshed;
	 }
	 X = X.parent;
	 }
	 
	 **/
	assert(0);
}


- (ETUUID *)newPersistentRootCopyingBranch: (ETUUID *)srcBranch
								insertInto: (ETUUID *)aDest
{
	COStoreItem *i1 = [COStoreItem item];
	
	COStoreItem *i2 = [[[self _storeItemForUUID: srcBranch] copy] autorelease];
	[i2 setUUID: [ETUUID UUID]]; // Give it a new UUID
	
	[i1 setValue: @"persistentRoot"
	forAttribute: @"type"
			type: COPrimitiveType(kCOPrimitiveTypeString)];	
	[i1 setValue: @"test document"
	forAttribute: @"name"
			type: COPrimitiveType(kCOPrimitiveTypeString)];
	[i1 setValue: [COPath pathWithPathComponent: [i2 UUID]]
	forAttribute: @"currentBranch"
			type: COPrimitiveType(kCOPrimitiveTypePath)];	
	[i1 setValue: S([i2 UUID])
	forAttribute: @"contents"
			type: COSetContainerType(kCOPrimitiveTypeEmbeddedItem)];
	
	assert([[i2 valueForAttribute: @"type"] isEqual: @"branch"]);
	assert([[i2 typeForAttribute: @"tracking"] isEqual: COPrimitiveType(kCOPrimitiveTypeCommitUUID)]);
	
	// insert
	
	COStoreItem *destItem = [self _storeItemForUUID: aDest];
	assert(destItem != nil);
	
	NSSet *destContents = [destItem valueForAttribute: @"contents"];
	// FIXME: Factor out!
	
	if (destContents == nil)
	{
		destContents = S([i1 UUID]);
	}
	else
	{
		assert([destContents isKindOfClass: [NSSet class]]);
		destContents = [destContents setByAddingObject: [i1 UUID]];
	}
	
	[destItem setValue: destContents
		  forAttribute: @"contents"
				  type: COSetContainerType(kCOPrimitiveTypeEmbeddedItem)];
	
	[self _insertOrUpdateItems: S(i1, i2, destItem)];
	
	return [i1 UUID];
}


- (ETUUID *) createBranchOfPersistentRoot: (ETUUID *)aRoot
{
	COStoreItem *proot = [self _storeItemForUUID: aRoot];
	COStoreItem *branch = [self _storeItemForUUID: [self currentBranchOfPersistentRoot: aRoot]];
	[branch setUUID: [ETUUID UUID]]; // makes it a copy.
	
	// update proot contents
	
	assert(proot != nil);
	
	NSSet *prootContents = [proot valueForAttribute: @"contents"];
	assert(prootContents != nil);
	assert([prootContents isKindOfClass: [NSSet class]]);
	
	prootContents = [prootContents setByAddingObject: [branch UUID]];
	
	[proot setValue: prootContents
		  forAttribute: @"contents"
			type: COSetContainerType(kCOPrimitiveTypeEmbeddedItem)];
	
	
	[self _insertOrUpdateItems: S(proot, branch)];
	
	return [branch UUID];
}

@end
