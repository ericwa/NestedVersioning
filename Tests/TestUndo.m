#import "TestCommon.h"

@interface TestUndo : NSObject <UKTest> {
	
}

@end

@implementation TestUndo

- (void) testUndo
{
	// commits in the persistent root
	
	COUUID *commit1 = nil; // initial commit, "red"
	COUUID *commit2 = nil; // "orange"
	COUUID *commit3 = nil; // "yellow"
	COUUID *commit4 = nil; // "green"
	
	
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
	
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	
	
	// switch to Branch B
	
	[[COSubtreeFactory factory] setCurrentBranch:u1BranchB forPersistentRoot:i1];
	UKTrue(u1BranchB == [[COSubtreeFactory factory] currentBranchOfPersistentRoot: i1]);
	
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
	
	UKStringsEqual(@"yellow", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"yellow", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	{
		COPersistentRootEditingContext *ctx4 = [ctx editingContextForEditingEmbdeddedPersistentRoot: i1];
		COSubtree *contents4 = [ctx4 persistentRootTree];
		[contents4 setPrimitiveValue: @"green"
						forAttribute: @"color"
								type: [COType stringType]];
		commit4 = [ctx4 commitWithMetadata: nil];
	}
	
	UKStringsEqual(@"green", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"green", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	
	
	
	
	// finally, test undo/redo.
	
	
	
	// reopen the context to avoid a merge.
	// FIXME: shouldn't be necessary
	
	ctx = [store rootContext];
	i1 = [[ctx persistentRootTree] subtreeWithUUID: [i1 UUID]];
	u1BranchA = [[ctx persistentRootTree] subtreeWithUUID: [u1BranchA UUID]];
	u1BranchB = [[ctx persistentRootTree] subtreeWithUUID: [u1BranchB UUID]];
	
	
	[[COSubtreeFactory factory] undoBranch: [[COSubtreeFactory factory] currentBranch: i1] store: store];
	[ctx commitWithMetadata: nil];
	
	UKStringsEqual(@"yellow", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"yellow", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	
	
	
	
	[[COSubtreeFactory factory] undoBranch: [[COSubtreeFactory factory] currentBranch: i1] store: store];
	[ctx commitWithMetadata: nil];
	
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	
	
	[[COSubtreeFactory factory] undoBranch: [[COSubtreeFactory factory] currentBranch: i1] store: store]; // does nothing - because we can't undo past the point where Branch B was created
	[ctx commitWithMetadata: nil];
	
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	

	// ensure that a GC here does not delete any commits we need
	{
		NSUInteger commitsBefore = [[store allCommitUUIDs] count];
		[store gc];
		NSUInteger commitsAfter = [[store allCommitUUIDs] count];
		UKTrue(commitsAfter < commitsBefore);
	}
	
	[[COSubtreeFactory factory] redoBranch: [[COSubtreeFactory factory] currentBranch: i1] store: store];
	[ctx commitWithMetadata: nil];
	
	UKStringsEqual(@"yellow", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"yellow", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	
	
	[[COSubtreeFactory factory] redoBranch: [[COSubtreeFactory factory] currentBranch: i1] store: store];
	[ctx commitWithMetadata: nil];
	
	UKStringsEqual(@"green", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"green", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	
	
	
	[[COSubtreeFactory factory] redoBranch: [[COSubtreeFactory factory] currentBranch: i1] store: store]; // does nothing - because we can't redo past the end of the branch
	[ctx commitWithMetadata: nil];
	
	UKStringsEqual(@"green", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"green", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
	
	
	
	[[COSubtreeFactory factory] undoBranch: [[COSubtreeFactory factory] currentBranch: i1] store: store]; 
	[[COSubtreeFactory factory] undoBranch: [[COSubtreeFactory factory] currentBranch: i1] store: store];
	[ctx commitWithMetadata: nil];
	
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	

	
	// now test creating an implict branch by committing in the persistent root again
	
	
	{
		COPersistentRootEditingContext *ctx3 = [ctx editingContextForEditingEmbdeddedPersistentRoot: i1];
		COSubtree *contents3 = [ctx3 persistentRootTree];
		[contents3 setPrimitiveValue: @"pink"
						forAttribute: @"color"
								type: [COType stringType]];
		commit3 = [ctx3 commitWithMetadata: nil];
	}
	
	UKStringsEqual(@"pink", [[[ctx editingContextForEditingEmbdeddedPersistentRoot: i1] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"orange", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchA] persistentRootTree] valueForAttribute: @"color"]);
	UKStringsEqual(@"pink", [[[ctx editingContextForEditingBranchOfPersistentRoot: u1BranchB] persistentRootTree] valueForAttribute: @"color"]);	
	
}

- (void) testSelectiveUndoWithNestedPersistentRootMerge
{
	COStore *store = setupStore();
	COSubtree *innerdoc;
	COSubtree *outerdoc;	
	
	{
		COSubtree *tree = [COSubtree subtree];
		[tree setValue: A(@"a", @"c", @"d")
		  forAttribute: @"letters"
				  type: [COType arrayWithPrimitiveType: [COType stringType]]];
		
		innerdoc = [[COSubtreeFactory factory] createPersistentRootWithRootItem: tree
																	displayName: @"My Inner Document"
																		  store: store];
	}
	
	outerdoc = [[COSubtreeFactory factory] createPersistentRootWithRootItem: innerdoc
																displayName: @"My Outer Document"
																	  store: store];
	
	// Set outerdoc as the store root.
	
	COPersistentRootEditingContext *ctx = [store rootContext];
	[ctx setPersistentRootTree: outerdoc];
	[ctx commitWithMetadata: nil];
	
	COUUID *state0 = [store rootVersion]; // { "a", "c", "d" }
	
	
	// make a commit on innerdoc
	
	{
		COPath *path = [[COPath pathWithPathComponent: [outerdoc UUID]]
						pathByAppendingPathComponent: [innerdoc UUID]];
		COPersistentRootEditingContext *ctx2 = [COPersistentRootEditingContext editingContextForEditingPath: path
																									inStore: store];	
		COSubtree *tree = [ctx2 persistentRootTree];
		[tree addObject: @"b" toOrderedAttribute: @"letters" atIndex: 1 type: [COType arrayWithPrimitiveType: [COType stringType]]];		
		[ctx2 commitWithMetadata: nil];
	}

	COUUID *state1 = [store rootVersion]; // { "a", "b", "c", "d" }
	
	// make a commit on innerdoc
	
	{
		COPath *path = [[COPath pathWithPathComponent: [outerdoc UUID]]
						pathByAppendingPathComponent: [innerdoc UUID]];
		COPersistentRootEditingContext *ctx2 = [COPersistentRootEditingContext editingContextForEditingPath: path
																									inStore: store];	
		COSubtree *tree = [ctx2 persistentRootTree];
		[tree addObject: @"e" toOrderedAttribute: @"letters" atIndex: 4 type: [COType arrayWithPrimitiveType: [COType stringType]]];		
		[ctx2 commitWithMetadata: nil];
	}
	
	COUUID *state2 = [store rootVersion]; // { "a", "b", "c", "d", "e" }	
	
	// check contents
		
	{
		COPath *path = [[COPath pathWithPathComponent: [outerdoc UUID]]
						pathByAppendingPathComponent: [innerdoc UUID]];
		COPersistentRootEditingContext *ctx2 = [COPersistentRootEditingContext editingContextForEditingPath: path
																									inStore: store];
		UKObjectsEqual(A(@"a", @"b", @"c", @"d", @"e"),
					   [[ctx2 persistentRootTree] valueForAttribute: @"letters"]);
	}
	
	// reopen the context to avoid a merge.
	// FIXME: shouldn't be necessary
	
	ctx = [store rootContext];
	
	COSubtreeDiff *diff = [[COSubtreeFactory factory] selectiveUndoCommit: state1
																forCommit: state2
																	store: store];
	UKNotNil(diff);
	UKFalse([diff hasConflicts]);
	
	if (diff != nil && ![diff hasConflicts])
	{
		COSubtree *result = [diff subtreeWithDiffAppliedToSubtree: [ctx persistentRootTree]];
		
		[ctx setPersistentRootTree: result];
		[ctx commitWithMetadata: nil];
	}
	
	// check contents
	
	{
		COPath *path = [[COPath pathWithPathComponent: [outerdoc UUID]]
						pathByAppendingPathComponent: [innerdoc UUID]];
		COPersistentRootEditingContext *ctx2 = [COPersistentRootEditingContext editingContextForEditingPath: path
																									inStore: store];
		UKObjectsEqual(A(@"a", @"c", @"d", @"e"),
					   [[ctx2 persistentRootTree] valueForAttribute: @"letters"]);
	}
}


@end
