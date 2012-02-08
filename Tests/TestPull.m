#import "TestCommon.h"

void testPull()
{
	// commits in the persistent root
	
	ETUUID *commit1 = nil; // initial commit, "red"
	ETUUID *commit2 = nil; // "orange"
	ETUUID *commit3 = nil; // "yellow"
	
	
	// setup a simple persistent root containing { "color" : "red" }
	
	COStore *store = setupStore();
	
	COPersistentRootEditingContext *ctx = [store rootContext];
	COSubtree *iroot = [COSubtree subtree];
	
	[ctx setPersistentRootTree: iroot];
	
	
	COSubtree *contents1 = [COSubtree subtree];
	[contents1 setPrimitiveValue: @"red"
					forAttribute: @"color"
							type: [COType stringType]];
	
	COSubtree *i1 = [[COSubtreeFactory factory] createPersistentRootWithRootItem: contents1
																	 displayName: @"My Document"
																		   store: store];
	
	// set up a second branch, branch B.
	
	COSubtree *u1BranchA = [[COSubtreeFactory factory] currentBranchOfPersistentRoot: i1];
	COSubtree *u1BranchB = [[COSubtreeFactory factory] createBranchOfPersistentRoot: i1];
	[u1BranchA setPrimitiveValue: @"Branch A" forAttribute: @"name" type: [COType stringType]];
	[u1BranchB setPrimitiveValue: @"Branch B" forAttribute: @"name" type: [COType stringType]];
	
	
	[iroot addTree: i1];
	
	[ctx commitWithMetadata: nil];
	
	
	// make a commit in the persistent root (which is on branch A) { "color" : "orange" }
	
	{
		COPersistentRootEditingContext *ctx2 = [ctx editingContextForEditingEmbdeddedPersistentRoot: i1];
		COSubtree *contents2 = [ctx2 persistentRootTree];
		[contents2 setPrimitiveValue: @"orange"
						forAttribute: @"color"
								type: [COType stringType]];
		
		commit2 = [ctx2 commitWithMetadata: nil];
		commit1 = [store parentForCommit: commit2];
	}
	
	// make a commit in the persistent root (which is on branch A) { "color" : "yellow" }
	
	{
		COPersistentRootEditingContext *ctx3 = [ctx editingContextForEditingEmbdeddedPersistentRoot: i1];
		COSubtree *contents3 = [ctx3 persistentRootTree];
		[contents3 setPrimitiveValue: @"yellow"
						forAttribute: @"color"
								type: [COType stringType]];
		commit3 = [ctx3 commitWithMetadata: nil];
	}
	
		
	// reopen the context to avoid a merge.
	// FIXME: shouldn't be necessary
	
	ctx = [store rootContext];
	i1 = [[ctx persistentRootTree] subtreeWithUUID: [i1 UUID]];
	u1BranchA = [[ctx persistentRootTree] subtreeWithUUID: [u1BranchA UUID]];
	u1BranchB = [[ctx persistentRootTree] subtreeWithUUID: [u1BranchB UUID]];
		
	
	// test that we can read the document contents as expected.
	
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"red", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	
	// now, suppose we want to pull the changes made in branch A into branch B.
	// this will be a simple fast-forward merge.
	
	[[COSubtreeFactory factory] pullChangesFromBranch: u1BranchA
											 toBranch: u1BranchB
												store: store];
	
	[ctx commitWithMetadata: nil];
	
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	EWTestEqual(@"yellow", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
}