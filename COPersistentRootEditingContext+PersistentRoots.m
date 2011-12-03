#import "COPersistentRootEditingContext+PersistentRoots.h"
#import "COPersistentRootEditingContext+Convenience.h"
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
	forAttribute: @"currentVersion"
			type: COPrimitiveType(kCOPrimitiveTypeCommitUUID)];		
	[i2 setValue: nestedDocumentInitialVersion
	forAttribute: @"head"
			type: COPrimitiveType(kCOPrimitiveTypeCommitUUID)];	// limit for redo. moved on every commit.
	
	[self insertValue: [i1 UUID]
		primitiveType: kCOPrimitiveTypeEmbeddedItem
	   inSetAttribute: @"contents"
			 ofObject: aDest];
		 
	[self _insertOrUpdateItems: S(i1, i2)];

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
	COPath *aPath = [root valueForAttribute: @"currentBranch"];
	
	assert([aPath isKindOfClass: [COPath class]]);
	// FIXME: check it is a single-element path
	
	return [aPath lastPathComponent];	
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
		forAttribute: @"currentVersion"
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
	 a) look up the version that "currentVersion" points to
	 b) get its parent (if it has none, can't undo)
	 c) set "currentVersion" to the parent, without modifying head
	 
	 */	
	assert(0);
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
	assert(0);
}


- (ETUUID *)createAndInsertNewPersistentRootByCopyingBranch: (ETUUID *)srcBranch
											 inItemWithUUID: (ETUUID *)aDest
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
	assert([[i2 typeForAttribute: @"currentVersion"] isEqual: COPrimitiveType(kCOPrimitiveTypeCommitUUID)]);
	
	[self insertValue: [i1 UUID]
		primitiveType: kCOPrimitiveTypeEmbeddedItem
	   inSetAttribute: @"contents"
			 ofObject: aDest];
	
	[self _insertOrUpdateItems: S(i1, i2)];
	
	return [i1 UUID];
}


- (ETUUID *) createBranchOfPersistentRoot: (ETUUID *)aRoot
{
	COStoreItem *branch = [self _storeItemForUUID: [self currentBranchOfPersistentRoot: aRoot]];
	[branch setUUID: [ETUUID UUID]]; // makes it a copy.

	[self insertValue: [branch UUID]
		primitiveType: kCOPrimitiveTypeEmbeddedItem
	   inSetAttribute: @"contents"
			 ofObject: aRoot];

	[self _insertOrUpdateItems: S(branch)];
	
	return [branch UUID];
}

@end
