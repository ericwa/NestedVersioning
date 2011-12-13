#import "TestCommon.h"

void testUndo()
{
	// commits in the persistent root
	
	ETUUID *commit1 = nil; // initial commit, "red"
	ETUUID *commit2 = nil; // "orange"
	ETUUID *commit3 = nil; // "yellow"
	ETUUID *commit4 = nil; // "green"
	
	
	// setup a simple persistent root containing { "color" : "red" }
	
	COStore *store = setupStore();

	COPersistentRootEditingContext *ctx = [store rootContext];
	COMutableItem *iroot = [COMutableItem item];
	ETUUID *uroot = [iroot UUID];
	
	[ctx _insertOrUpdateItems: S(iroot)
		newRootEmbeddedObject: uroot];
	
		
	COItemTreeNode *contents1 = [COItemTreeNode itemTree];
	[contents1 setValue: @"red"
		   forAttribute: @"color"
				   type: [COType stringType]];
	ETUUID *contentsUUID = [contents1 UUID];

	ETUUID *u1 = [ctx createAndInsertNewPersistentRootWithRootItem: contents1
													inItemWithUUID: uroot];
	
	[ctx commitWithMetadata: nil];
	
	
	
	
	// make a commit in the persistent root { "color" : "orange" }
	
	{
		COPersistentRootEditingContext *ctx2 = [ctx editingContextForEditingEmbdeddedPersistentRoot: u1];
		COMutableItem *contents2 = [ctx2 _storeItemForUUID: [ctx2 rootUUID]];
		[contents2 setValue: @"orange"
			   forAttribute: @"color"
					   type: [COType stringType]];
		[ctx2 _insertOrUpdateItems: S(contents2)];
		commit2 = [ctx2 commitWithMetadata: nil];
		
		commit1 = [store parentForCommit: commit2];
		assert(commit1 != nil);
	}
	
	
	
	
	// reopen the context to avoid a merge.
	// FIXME: shouldn't be necessary
	
	ctx = [store rootContext];
	
	
	
	
	// cretate a branch; label the branches
	
	ETUUID *u1BranchA = [ctx currentBranchOfPersistentRoot: u1];
	ETUUID *u1BranchB = [ctx createBranchOfPersistentRoot: u1];
	
	{
		COMutableItem *u1BranchAItem = [ctx _storeItemForUUID: u1BranchA];
		[u1BranchAItem setValue: @"Branch A" forAttribute: @"name" type: [COType stringType]];
		[ctx _insertOrUpdateItems: S(u1BranchAItem)];
	}
	{
		COMutableItem *u1BranchBItem = [ctx _storeItemForUUID: u1BranchB];
		[u1BranchBItem setValue: @"Branch B" forAttribute: @"name" type: [COType stringType]];
		[ctx _insertOrUpdateItems: S(u1BranchBItem)];
	}
	
	[ctx commitWithMetadata: nil];

	
	
	
	// test that we can read the document contents.
	
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchA] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchB] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);	
	
	
	
	// switch to Branch B
	
	[ctx setCurrentBranch: u1BranchB
		forPersistentRoot: u1];
	EWTestEqual(u1BranchB, [ctx currentBranchOfPersistentRoot: u1]);
	
	[ctx commitWithMetadata: nil];
	
	
	
	
	// make 2 commits in the persistent root, "yellow", "green"
	
	{
		COPersistentRootEditingContext *ctx3 = [ctx editingContextForEditingEmbdeddedPersistentRoot: u1];
		COMutableItem *contents3 = [ctx3 _storeItemForUUID: [ctx3 rootUUID]];
		[contents3 setValue: @"yellow"
			   forAttribute: @"color"
					   type: [COType stringType]];
		[ctx3 _insertOrUpdateItems: S(contents3)];
		commit3 = [ctx3 commitWithMetadata: nil];
	}
	
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchA] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchB] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);	
	
	{
		COPersistentRootEditingContext *ctx4 = [ctx editingContextForEditingEmbdeddedPersistentRoot: u1];
		COMutableItem *contents4 = [ctx4 _storeItemForUUID: [ctx4 rootUUID]];
		[contents4 setValue: @"green"
			   forAttribute: @"color"
					   type: [COType stringType]];
		[ctx4 _insertOrUpdateItems: S(contents4)];
		commit4 = [ctx4 commitWithMetadata: nil];
	}
	
	EWTestEqual(@"green", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchA] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"green", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchB] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);	
	
	
	
	
	
	// finally, test undo/redo.
	
	
	
	// reopen the context to avoid a merge.
	// FIXME: shouldn't be necessary
	
	ctx = [store rootContext];
	
	[ctx undoPersistentRoot: u1];
	[ctx commitWithMetadata: nil];
	
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchA] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchB] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);	
	
	
	
	
	
	[ctx undoPersistentRoot: u1];
	[ctx commitWithMetadata: nil];
	
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchA] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchB] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);	
	
	
	
	[ctx undoPersistentRoot: u1]; // does nothing - because we can't undo past the point where Branch B was created
	[ctx commitWithMetadata: nil];
	
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchA] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchB] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);	
	

	// ensure that a GC here does not delete any commits we need
	{
		NSUInteger commitsBefore = [[store allCommitUUIDs] count];
		[store gc];
		NSUInteger commitsAfter = [[store allCommitUUIDs] count];
		EWTestTrue(commitsAfter < commitsBefore);
	}
	
	[ctx redoPersistentRoot: u1];
	[ctx commitWithMetadata: nil];
	
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchA] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchB] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);	
	
	
	
	[ctx redoPersistentRoot: u1];
	[ctx commitWithMetadata: nil];
	
	EWTestEqual(@"green", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchA] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"green", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchB] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);	
	
	
	
	
	[ctx redoPersistentRoot: u1]; // does nothing - because we can't redo past the end of the branch
	[ctx commitWithMetadata: nil];
	
	EWTestEqual(@"green", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchA] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"green", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchB] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);	
	
	
	
	
	[ctx undoPersistentRoot: u1]; 
	[ctx undoPersistentRoot: u1]; 
	[ctx commitWithMetadata: nil];
	
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchA] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchB] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);	
	

	
	// now test creating an implict branch by committing in the persistent root again
	
	
	{
		COPersistentRootEditingContext *ctx3 = [ctx editingContextForEditingEmbdeddedPersistentRoot: u1];
		COMutableItem *contents3 = [ctx3 _storeItemForUUID: [ctx3 rootUUID]];
		[contents3 setValue: @"pink"
			   forAttribute: @"color"
					   type: [COType stringType]];
		[ctx3 _insertOrUpdateItems: S(contents3)];
		commit3 = [ctx3 commitWithMetadata: nil];
	}
	
	EWTestEqual(@"pink", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchA] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);
	EWTestEqual(@"pink", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: u1 onBranch: u1BranchB] _storeItemForUUID: contentsUUID] valueForAttribute: @"color"]);	
	
}