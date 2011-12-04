#import "TestCommon.h"

void testUndo()
{
	// setup a simple persistent root containing { "color" : "red" }
	
	COStore *store = setupStore();

	COPersistentRootEditingContext *ctx = [store rootContext];
	COStoreItem *iroot = [COStoreItem item];
	ETUUID *uroot = [iroot UUID];
	
	[ctx _insertOrUpdateItems: S(iroot)
		newRootEmbeddedObject: uroot];
	
		
	COStoreItem *contents1 = [COStoreItem item];
	[contents1 setValue: @"red"
		   forAttribute: @"color"
				   type: COPrimitiveType(kCOPrimitiveTypeString)];
	ETUUID *contentsUUID = [contents1 UUID];

	ETUUID *u1 = [ctx createAndInsertNewPersistentRootWithRootItem: contents1
													inItemWithUUID: uroot];
	
	[ctx commitWithMetadata: nil];
	
	
	// make a commit in the persistent root { "color" : "orange" }
	
	{
		COPersistentRootEditingContext *ctx2 = [ctx editingContextForEditingEmbdeddedPersistentRoot: u1];
		COStoreItem *contents2 = [ctx2 _storeItemForUUID: [ctx2 rootUUID]];
		[contents2 setValue: @"orange"
				   forAttribute: @"color"
						   type: COPrimitiveType(kCOPrimitiveTypeString)];
		[ctx2 _insertOrUpdateItems: S(contents2)];
		[ctx2 commitWithMetadata: nil];
	}
	
	// cretate a branch; label the branches
	
	ETUUID *u1BranchA = [ctx currentBranchOfPersistentRoot: u1];
	ETUUID *u1BranchB = [ctx createBranchOfPersistentRoot: u1];
	
	{
		COStoreItem *u1BranchAItem = [ctx _storeItemForUUID: u1BranchA];
		[u1BranchAItem setValue: @"Branch A" forAttribute: @"name" type: COPrimitiveType(kCOPrimitiveTypeString)];
		[ctx _insertOrUpdateItems: S(u1BranchAItem)];
	}
	{
		COStoreItem *u1BranchBItem = [ctx _storeItemForUUID: u1BranchB];
		[u1BranchBItem setValue: @"Branch B" forAttribute: @"name" type: COPrimitiveType(kCOPrimitiveTypeString)];
		[ctx _insertOrUpdateItems: S(u1BranchBItem)];
	}
	
	[ctx commitWithMetadata: nil];

	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchA] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchB] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);	
	
	
	/*
	
	EWTestEqual(u1BranchA, [ctx currentBranchOfPersistentRoot: u1]);
	EWTestEqual(S(u1BranchA, u1BranchB), [ctx branchesOfPersistentRoot: u1]);
	
	
	[ctx setCurrentBranch: u1BranchB
		forPersistentRoot: u1];
	
	EWTestEqual(u1BranchB, [ctx currentBranchOfPersistentRoot: u1]);
	
	[ctx setCurrentBranch: u1BranchA
		forPersistentRoot: u1];
	
	EWTestEqual(u1BranchA, [ctx currentBranchOfPersistentRoot: u1]);
	
	//
	// 2c. create another persistent root containing a copy of u1BranchB
	//
	
	ETUUID *u2 = [ctx createAndInsertNewPersistentRootByCopyingBranch: u1BranchB
													   inItemWithUUID: uroot];
	
	//
	// 2d. commit changes
	//
	
	ETUUID *firstVersion = [ctx commitWithMetadata: nil];
	EWTestTrue(firstVersion != nil);
	EWTestEqual(firstVersion, [store rootVersion]);
	
	
	//
	// 3. Now open an embedded context on the document
	//
	
	COPersistentRootEditingContext *ctx2 = [ctx editingContextForEditingEmbdeddedPersistentRoot: u1];
	EWTestTrue(nil != ctx2);
	EWTestEqual([nestedDocumentRootItem UUID], [ctx2 rootUUID]);
	
	//
	// 4. Try making a commit in the document
	//
	
	
	COStoreItem *nestedDocCtx2 = [ctx2 _storeItemForUUID: [nestedDocumentRootItem UUID]];
	EWTestEqual(nestedDocumentRootItem, nestedDocCtx2);
	
	[nestedDocCtx2 setValue: @"green"
			   forAttribute: @"color"
					   type: COPrimitiveType(kCOPrimitiveTypeString)];
	
	[ctx2 _insertOrUpdateItems: S(nestedDocCtx2)];
	
	ETUUID *commitInNestedDocCtx2 = [ctx2 commitWithMetadata: nil];
	
	EWTestTrue(nil != commitInNestedDocCtx2);
	
	
	//
	// 5. Reopen store and check that we read back the same data
	//
	
	[store release];
	
	
	COStore *store2 = [[COStore alloc] initWithURL: [NSURL fileURLWithPath: STOREPATH]];
	
	id<COEditingContext> testctx1 = [store2 rootContext];
	
	{
		id<COEditingContext> testctx2 = [testctx1 editingContextForEditingEmbdeddedPersistentRoot: u1];
		
		COStoreItem *item = [testctx2 _storeItemForUUID: [testctx2 rootUUID]];
		EWTestEqual(@"green", [item valueForAttribute: @"color"]);
		EWTestEqual(nestedDocCtx2, item);
	}
	
	{
		id<COEditingContext> testctx2 = [testctx1 editingContextForEditingEmbdeddedPersistentRoot: u1
																						 onBranch: u1BranchB];
		COStoreItem *item = [testctx2 _storeItemForUUID: [testctx2 rootUUID]];
		EWTestEqual(@"red", [item valueForAttribute: @"color"]);
		EWTestEqual(nestedDocumentRootItem, item);
	}
	
	{
		id<COEditingContext> testctx2 = [testctx1 editingContextForEditingEmbdeddedPersistentRoot: u2];
		COStoreItem *item = [testctx2 _storeItemForUUID: [testctx2 rootUUID]];
		EWTestEqual(@"red", [item valueForAttribute: @"color"]);
		EWTestEqual(nestedDocumentRootItem, item);
	}
	
	[store2 release];
	
	
	//
	// 6. GC the store
	// 
	
	NSUInteger commitsBefore = [[store2 allCommitUUIDs] count];
	[store2 gc];
	NSUInteger commitsAfter = [[store2 allCommitUUIDs] count];
	EWTestTrue(commitsAfter < commitsBefore);
	*/
}