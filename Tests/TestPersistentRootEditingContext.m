#import "TestCommon.h"

@interface TestPersistentRootEditingContext : NSObject <UKTest> {
	
}

@end

@implementation  TestPersistentRootEditingContext

- (void) testBasic
{
	COStore *store = setupStore();
	
	//	
	// 1. set up the root context
	//	
	
	COPersistentRootEditingContext *ctx = [store rootContext];
	
	// at this point the context is empty.
	// in particular, it has no persistentRootTree, which means it contains no embedded objets.
	// this means we can't commit.
	
	UKNil([ctx persistentRootTree]);
	
	COSubtree *iroot = [COSubtree subtree];
	
	[ctx setPersistentRootTree: iroot];
	
	//	
	// 2.  set up a nested persistent root
	//
	
	COSubtree *nestedDocumentRootItem = [COSubtree subtree];
	[nestedDocumentRootItem setPrimitiveValue: @"red"
								 forAttribute: @"color"
										 type: [COType stringType]];
	
	COSubtree *u1Tree = [[COSubtreeFactory factory] createPersistentRootWithRootItem: nestedDocumentRootItem
																		 displayName: @"My Document"
																			   store: store];
	[iroot addTree: u1Tree];
	
	
	UKIntsEqual(1, [[[COSubtreeFactory factory] branchesOfPersistentRoot: u1Tree] count]);
	
	//
	// 2b. create another branch
	//
	
	COSubtree *u1BranchA = [[COSubtreeFactory factory] currentBranchOfPersistentRoot: u1Tree];
	COSubtree *u1BranchB = [[COSubtreeFactory factory] createBranchOfPersistentRoot: u1Tree];
	
	[u1BranchA setPrimitiveValue: @"Development Branch" forAttribute: @"name" type: [COType stringType]];
	[u1BranchB setPrimitiveValue: @"Stable Branch" forAttribute: @"name" type: [COType stringType]];	
	
	UKObjectsEqual(u1BranchA, [[COSubtreeFactory factory] currentBranchOfPersistentRoot: u1Tree]);
	UKObjectsEqual(S(u1BranchA, u1BranchB), [[COSubtreeFactory factory] branchesOfPersistentRoot: u1Tree]);
	
	
	[[COSubtreeFactory factory] setCurrentBranch: u1BranchB
							   forPersistentRoot: u1Tree];
	
	UKObjectsEqual(u1BranchB, [[COSubtreeFactory factory] currentBranchOfPersistentRoot: u1Tree]);
	
	[[COSubtreeFactory factory] setCurrentBranch: u1BranchA
							   forPersistentRoot: u1Tree];
	
	UKObjectsEqual(u1BranchA, [[COSubtreeFactory factory] currentBranchOfPersistentRoot: u1Tree]);
	
	//
	// 2c. create another persistent root containing a copy of u1BranchB
	//
	
	COSubtree *u2 = [[COSubtreeFactory factory] persistentRootByCopyingBranch:  u1BranchB];
	[iroot addTree: u2];
	
	//
	// 2d. commit changes
	//
	
	ETUUID *firstVersion = [ctx commitWithMetadata: nil];
	UKNotNil(firstVersion);
	UKObjectsEqual(firstVersion, [store rootVersion]);
	
	
	//
	// 3. Now open an embedded context on the document
	//
	
	COPersistentRootEditingContext *ctx2 = [ctx editingContextForEditingEmbdeddedPersistentRoot: u1Tree];
	UKNotNil(ctx2);
	UKObjectsEqual([nestedDocumentRootItem UUID], [[ctx2 persistentRootTree] UUID]);
	
	//
	// 4. Try making a commit in the document
	//
	
	COSubtree *nestedDocCtx2 = [ctx2 persistentRootTree];
	//UKObjectsEqual(nestedDocumentRootItem, nestedDocCtx2);
	
	[nestedDocCtx2 setPrimitiveValue: @"green"
						forAttribute: @"color"
								type: [COType stringType]];
	
	ETUUID *commitInNestedDocCtx2 = [ctx2 commitWithMetadata: nil];
	
	UKNotNil(commitInNestedDocCtx2);
	
	
	//
	// 5. Reopen store and check that we read back the same data
	//
	
	[store release];
	
	
	COStore *store2 = [[COStore alloc] initWithURL: [NSURL fileURLWithPath: STOREPATH]];
	
	COPersistentRootEditingContext *testctx1 = [store2 rootContext];
	
	u1Tree = [[testctx1 persistentRootTree] subtreeWithUUID: [u1Tree UUID]];
	u1BranchB = [[testctx1 persistentRootTree] subtreeWithUUID: [u1BranchB  UUID]];
	u2 = [[testctx1 persistentRootTree] subtreeWithUUID: [u2 UUID]];
	
	{
		COPersistentRootEditingContext *testctx2 = [testctx1 editingContextForEditingEmbdeddedPersistentRoot: u1Tree];
		
		COSubtree *item = [testctx2 persistentRootTree];
		UKStringsEqual(@"green", [item valueForAttribute: @"color"]);
		UKObjectsEqual(nestedDocCtx2, item);
	}
	
	{
		COPersistentRootEditingContext *testctx2 = [testctx1 editingContextForEditingBranchOfPersistentRoot: u1BranchB];
		COSubtree *item = [testctx2 persistentRootTree];
		UKStringsEqual(@"red", [item valueForAttribute: @"color"]);
		//UKObjectsEqual(nestedDocumentRootItem, item);
	}
	
	{
		COPersistentRootEditingContext *testctx2 = [testctx1 editingContextForEditingEmbdeddedPersistentRoot: u2];
		COSubtree *item = [testctx2 persistentRootTree];
		UKStringsEqual(@"red", [item valueForAttribute: @"color"]);
		//UKObjectsEqual(nestedDocumentRootItem, item);
	}
	
	
	//
	// 6. GC the store
	// 
	
	NSUInteger commitsBefore = [[store2 allCommitUUIDs] count];
	[store2 gc];
	NSUInteger commitsAfter = [[store2 allCommitUUIDs] count];
	UKTrue(commitsAfter < commitsBefore);
	
	
	[store2 release];	
}

@end