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
	COSubtree *iroot = [COSubtree subtree];
	
	[ctx setPersistentRootTree: iroot];
	
		
	COSubtree *contents1 = [COSubtree subtree];
	[contents1 setPrimitiveValue: @"red"
					forAttribute: @"color"
							type: [COType stringType]];

	COSubtree *i1 = [ctx createPersistentRootWithRootItem: contents1
											  displayName: @"My Document"];
	[iroot addTree: i1];
	
	[ctx commitWithMetadata: nil];
	
	
	
	
	// make a commit in the persistent root { "color" : "orange" }
	
	{
		COPersistentRootEditingContext *ctx2 = [ctx editingContextForEditingEmbdeddedPersistentRoot: i1];
		COSubtree *contents2 = [ctx2 persistentRootTree];
		[contents2 setPrimitiveValue: @"orange"
						forAttribute: @"color"
								type: [COType stringType]];

		commit2 = [ctx2 commitWithMetadata: nil];
		
		commit1 = [store parentForCommit: commit2];
		assert(commit1 != nil);
	}
	
	
	
	
	// reopen the context to avoid a merge.
	// FIXME: shouldn't be necessary
	
	ctx = [store rootContext];
	i1 = [[ctx persistentRootTree] subtreeWithUUID: [i1 UUID]];
	
	
	
	// cretate a branch; label the branches
	
	COSubtree *u1BranchA = [[COSubtreeFactory factory] currentBranchOfPersistentRoot: i1];
	COSubtree *u1BranchB = [[COSubtreeFactory factory] createBranchOfPersistentRoot: i1];
	[u1BranchA setPrimitiveValue: @"Branch A" forAttribute: @"name" type: [COType stringType]];
	[u1BranchB setPrimitiveValue: @"Branch B" forAttribute: @"name" type: [COType stringType]];
	
	[ctx commitWithMetadata: nil];

	
	
	
	// test that we can read the document contents.
	
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	
	
	// switch to Branch B
	
	[[COSubtreeFactory factory] setCurrentBranch:u1BranchB forPersistentRoot:i1];
	EWTestTrue(u1BranchB == [[COSubtreeFactory factory] currentBranchOfPersistentRoot: i1]);
	
	[ctx commitWithMetadata: nil];
	
	
	
	
	// make 2 commits in the persistent root, "yellow", "green"
	
	{
		COPersistentRootEditingContext *ctx3 = [ctx editingContextForEditingEmbdeddedPersistentRoot: i1];
		COSubtree *contents3 = [ctx3 persistentRootTree];
		[contents3 setPrimitiveValue: @"yellow"
						forAttribute: @"color"
								type: [COType stringType]];
		commit3 = [ctx3 commitWithMetadata: nil];
	}
	
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	{
		COPersistentRootEditingContext *ctx4 = [ctx editingContextForEditingEmbdeddedPersistentRoot: i1];
		COSubtree *contents4 = [ctx4 persistentRootTree];
		[contents4 setPrimitiveValue: @"green"
						forAttribute: @"color"
								type: [COType stringType]];
		commit4 = [ctx4 commitWithMetadata: nil];
	}
	
	EWTestEqual(@"green", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"green", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	
	
	
	
	// finally, test undo/redo.
	
	
	
	// reopen the context to avoid a merge.
	// FIXME: shouldn't be necessary
	
	ctx = [store rootContext];
	i1 = [[ctx persistentRootTree] subtreeWithUUID: [i1 UUID]];
	u1BranchA = [[ctx persistentRootTree] subtreeWithUUID: [u1BranchA UUID]];
	u1BranchB = [[ctx persistentRootTree] subtreeWithUUID: [u1BranchB UUID]];
	
	
	[ctx undoPersistentRoot: i1];
	[ctx commitWithMetadata: nil];
	
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	
	
	
	
	[ctx undoPersistentRoot: i1];
	[ctx commitWithMetadata: nil];
	
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	
	
	[ctx undoPersistentRoot: i1]; // does nothing - because we can't undo past the point where Branch B was created
	[ctx commitWithMetadata: nil];
	
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	

	// ensure that a GC here does not delete any commits we need
	{
		NSUInteger commitsBefore = [[store allCommitUUIDs] count];
		[store gc];
		NSUInteger commitsAfter = [[store allCommitUUIDs] count];
		EWTestTrue(commitsAfter < commitsBefore);
	}
	
	[ctx redoPersistentRoot: i1];
	[ctx commitWithMetadata: nil];
	
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	
	
	[ctx redoPersistentRoot: i1];
	[ctx commitWithMetadata: nil];
	
	EWTestEqual(@"green", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"green", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	
	
	
	[ctx redoPersistentRoot: i1]; // does nothing - because we can't redo past the end of the branch
	[ctx commitWithMetadata: nil];
	
	EWTestEqual(@"green", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"green", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	
	
	
	[ctx undoPersistentRoot: i1]; 
	[ctx undoPersistentRoot: i1]; 
	[ctx commitWithMetadata: nil];
	
	EWTestEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	

	
	// now test creating an implict branch by committing in the persistent root again
	
	
	{
		COPersistentRootEditingContext *ctx3 = [ctx editingContextForEditingEmbdeddedPersistentRoot: i1];
		COSubtree *contents3 = [ctx3 persistentRootTree];
		[contents3 setPrimitiveValue: @"pink"
						forAttribute: @"color"
								type: [COType stringType]];
		commit3 = [ctx3 commitWithMetadata: nil];
	}
	
	EWTestEqual(@"pink", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"pink", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
}