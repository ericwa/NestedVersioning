#import "TestCommon.h"

@interface TestSubtreeDiffMerge : NSObject <UKTest>
{
}

@end

@implementation TestSubtreeDiffMerge

- (void) testBasic
{
	COSubtree *t1 = [COSubtree subtree];
	COSubtree *t2 = [COSubtree subtree];	
	COSubtree *t3a = [COSubtree subtree];
	COSubtree *t3b = [COSubtree subtree];
	[t1 addTree: t2];
	[t2 addTree: t3a];
	[t2 addTree: t3b];
	
	
	// Create a copy and modify it.
	COSubtree *u1 = [[t1 copy] autorelease];
	
	UKObjectsEqual(u1, t1);
	
	COSubtree *u2 = [u1 subtreeWithUUID: [t2 UUID]];
	COSubtree *u3a = [u1 subtreeWithUUID: [t3a UUID]];
	
	[u2 removeSubtreeWithUUID: [t3b UUID]];
	
	COSubtree *u4 = [COSubtree subtree];
	[u3a addTree: u4];
	
	[u4 setPrimitiveValue: @"This node was added"
			 forAttribute: @"comment"
					 type: [COType stringType]];
	
	
	// Test creating a diff
	COSubtreeDiff *diff_t1_u1 = [COSubtreeDiff diffSubtree: t1 withSubtree: u1 sourceIdentifier: @"fixme"];
	
	COSubtree *u1_generated_from_diff = [diff_t1_u1 subtreeWithDiffAppliedToSubtree: t1];
	
	UKObjectsEqual(u1, u1_generated_from_diff);
}

- (void)testSelectiveUndoOfGroupOperation
{
	COSubtree *doc = [COSubtree subtree];
	COSubtree *line1 = [COSubtree subtree];
	COSubtree *circle1 = [COSubtree subtree];
	COSubtree *square1 = [COSubtree subtree];
	COSubtree *image1 = [COSubtree subtree];
	
	[line1 setValue: @"line1" forAttribute: @"label" type: [COType stringType]];	
	[circle1 setValue: @"circle1" forAttribute: @"label" type: [COType stringType]];
	[square1 setValue: @"square1" forAttribute: @"label" type: [COType stringType]];	
	[image1 setValue: @"image1" forAttribute: @"label" type: [COType stringType]];
	
	[doc setValue: A(line1, circle1, square1, image1)
	 forAttribute: @"contents"
			 type: [COType uniqueArrayWithPrimitiveType: [COType embeddedItemType]]];

	// snapshot the state: (line1, circle1, square1, image1) into doc2
	COSubtree *doc2 = [[doc copy] autorelease];
	
	COSubtree *group1 = [COSubtree subtree];
	[group1 setValue: @"group1" forAttribute: @"label" type: [COType stringType]];
	[doc addObject: group1 toOrderedAttribute: @"contents" atIndex: 1 type: [COType uniqueArrayWithPrimitiveType: [COType embeddedItemType]]];
	[group1 addTree: circle1];
	[group1 addTree: square1];
	
	// snapshot the state:  (line1, group1=(circle1, square1), image1) into ctx3
	COSubtree *doc3 = [[doc copy] autorelease];
	
	COSubtree *triangle1 = [COSubtree subtree];
	[triangle1 setValue: @"triangle1" forAttribute: @"label" type: [COType stringType]];
	[doc addObject: triangle1 toOrderedAttribute: @"contents" atIndex: 0 type: [COType uniqueArrayWithPrimitiveType: [COType embeddedItemType]]];
	
	
	// doc state:  (triangl1, line1, group1=(circle1, square1), image1)
	
	
	// ------------
	
	
	// Calculate diffs
	
	COSubtreeDiff *diff_doc3_vs_doc2 = [COSubtreeDiff diffSubtree: doc3 withSubtree: doc2 sourceIdentifier: @"fixme"];
	COSubtreeDiff *diff_doc3_vs_doc = [COSubtreeDiff diffSubtree: doc3 withSubtree: doc sourceIdentifier: @"fixme"];
	
	// Sanity check that the diffs work
	
	UKObjectsEqual(doc, [diff_doc3_vs_doc subtreeWithDiffAppliedToSubtree: doc3]);
	UKObjectsEqual(doc2, [diff_doc3_vs_doc2 subtreeWithDiffAppliedToSubtree: doc3]);
	
	COSubtreeDiff *diff_merged = [diff_doc3_vs_doc2 subtreeDiffByMergingWithDiff: diff_doc3_vs_doc];
	
	COSubtree *merged = [diff_merged subtreeWithDiffAppliedToSubtree: doc3];
	
	UKFalse([diff_merged hasConflicts]);
	
	UKObjectsEqual(A(triangle1, line1, circle1, square1, image1), [merged valueForAttribute: @"contents"]);
}

/**
 * This test creates a conflict where 
 */
- (void)testTreeConflict
{
	COSubtree *docO, *docA, *docB;
	
	// 1. Setup docO, docA, docB
	{
		COSubtree *doc = [COSubtree subtree];
		COSubtree *group1 = [COSubtree subtree];
		COSubtree *group2 = [COSubtree subtree];
		COSubtree *shape1 = [COSubtree subtree];
		
		[doc addTree: shape1];
		
		docO = [[doc copy] autorelease];
		
		[doc addTree: group1];
		[group1 addTree: shape1];
		
		docA = [[doc copy] autorelease];
		
		[doc addTree: group2];
		[group2 addTree: shape1];
		[doc removeSubtree: group1];
		
		docB = [[doc copy] autorelease];
	}
	
	COSubtreeDiff *diff_docO_vs_docA = [COSubtreeDiff diffSubtree: docO withSubtree: docA sourceIdentifier: @"fixme"];
	COSubtreeDiff *diff_docO_vs_docB = [COSubtreeDiff diffSubtree: docO withSubtree: docB sourceIdentifier: @"fixme"];
	
	// Sanity check that the diffs work
	
	UKObjectsEqual(docA, [diff_docO_vs_docA subtreeWithDiffAppliedToSubtree: docA]);
	UKObjectsEqual(docB, [diff_docO_vs_docB subtreeWithDiffAppliedToSubtree: docB]);
	
	COSubtreeDiff *diff_merged = [diff_docO_vs_docA subtreeDiffByMergingWithDiff: diff_docO_vs_docB];
	
	UKTrue([diff_merged hasConflicts]);
	
	// FIXME: finish test.
}


/*
 - (void) testSetPropertyDiffMerge
 {
 NSSet *set2 = S(@"A", @"b", @"d", @"zoo", @"e");
 NSSet *set1 = S(@"a", @"b", @"c", @"d", @"e");
 NSSet *set3 = S(@"A", @"b", @"c", @"e", @"foo");
 
 COSetDiff *diff12 = [[COSetDiff alloc] initWithFirstSet: set1 secondSet: set2 sourceIdentifier: @"diff12"];
 UKObjectsEqual(S(@"A", @"zoo"), [diff12 insertionSet]);
 UKObjectsEqual(S(@"a", @"c"), [diff12 deletionSet]);
 UKObjectsEqual(set2, [diff12 setWithDiffAppliedTo: set1]);
 
 COSetDiff *diff13 = [[COSetDiff alloc] initWithFirstSet: set1 secondSet: set3 sourceIdentifier: @"diff13"];
 UKObjectsEqual(S(@"A", @"foo"), [diff13 insertionSet]);
 UKObjectsEqual(S(@"a", @"d"), [diff13 deletionSet]);
 UKObjectsEqual(set3, [diff13 setWithDiffAppliedTo: set1]);
 
 COSetDiff *merged = [diff12 setDiffByMergingWithDiff: diff13];
 UKObjectsEqual(S(@"A", @"foo", @"zoo"), [merged insertionSet]);
 UKObjectsEqual(S(@"a", @"d", @"c"), [merged deletionSet]);
 UKObjectsEqual(S(@"A", @"b", @"zoo", @"e", @"foo"), [merged setWithDiffAppliedTo: set1]);
 
 UKObjectsEqual(S(@"A", @"zoo"), [merged insertionSetForSourceIdentifier: @"diff12"]);
 UKObjectsEqual(S(@"a", @"c"), [merged deletionSetForSourceIdentifier: @"diff12"]);
 UKObjectsEqual(S(@"A", @"foo"), [merged insertionSetForSourceIdentifier: @"diff13"]);
 UKObjectsEqual(S(@"a", @"d"), [merged deletionSetForSourceIdentifier: @"diff13"]);	
 }
 */


#pragma mark sequence diff merged

#if 0

- (void) testBasic
{
	NSArray *array2 = A(@"A", @"b", @"d", @"zoo", @"e");
	NSArray *array1 = A(@"a", @"b", @"c", @"d", @"e");
	NSArray *array3 = A(@"A", @"b", @"c", @"e", @"foo");
	
	/**
	 * modify a->A, remove c, insert 'zoo' after d
	 */
	COArrayDiff *diff12 = [[COArrayDiff alloc] initWithFirstArray: array1 secondArray: array2 sourceIdentifier: @"diff12"];
	
	/**
	 * modify a->A, remove d, insert 'foo' after e
	 */
	COArrayDiff *diff13 = [[COArrayDiff alloc] initWithFirstArray: array1 secondArray: array3 sourceIdentifier: @"diff13"];
	
	UKObjectsEqual(array2, [diff12 arrayWithDiffAppliedTo: array1]);
	UKObjectsEqual(array3, [diff13 arrayWithDiffAppliedTo: array1]);
	
	COArrayDiff *merged = (COArrayDiff *)[diff12 sequenceDiffByMergingWithDiff: diff13];
	UKFalse([merged hasConflicts]);
	
	// Expected: {a->A nonconflicting}, remove c, remove d,  insert 'zoo', insert 'foo'
	
	UKObjectsEqual(A(@"A", @"b", @"zoo", @"e", @"foo"), [merged arrayWithDiffAppliedTo: array1]);
	
	// Examine the a->A change group
	
	COOverlappingSequenceEditGroup *edit1 = (COOverlappingSequenceEditGroup *)[[merged operations] objectAtIndex: 0];
	
	UKObjectKindOf(edit1, COOverlappingSequenceEditGroup);
	UKFalse([edit1 hasConflicts]);
	UKIntsEqual(2, [[edit1 allEdits] count]);
	
	// Examine the a->A change from diff12
	
	NSArray *edit1diff12Array = [edit1 editsForSourceIdentifier: @"diff12"];
	UKIntsEqual(1, [edit1diff12Array count]);
	
	COSequenceModification *edit1diff12 = [edit1diff12Array objectAtIndex: 0];
	UKObjectKindOf(edit1diff12, COSequenceModification);
	UKObjectsEqual(A(@"A"), [edit1diff12 insertedObject]);
	UKTrue(NSEqualRanges(NSMakeRange(0, 1), [edit1diff12 range]));
	UKObjectsEqual(@"diff12", [edit1diff12 sourceIdentifier]);
	
	// Examine the a->A change from diff13
	
	NSArray *edit1diff13Array = [edit1 editsForSourceIdentifier: @"diff13"];
	UKIntsEqual(1, [edit1diff13Array count]);
	
	COSequenceModification *edit1diff13 = [edit1diff13Array objectAtIndex: 0];
	UKObjectKindOf(edit1diff13, COSequenceModification);
	UKObjectsEqual(A(@"A"), [edit1diff13 insertedObject]);
	UKTrue(NSEqualRanges(NSMakeRange(0, 1), [edit1diff13 range]));
	UKObjectsEqual(@"diff13", [edit1diff13 sourceIdentifier]);
	
	UKObjectsNotEqual(edit1diff12, edit1diff13); // because their sourceIdentifiers are different
	UKTrue([edit1diff12 isEqualIgnoringSourceIdentifier: edit1diff13]);	
}

- (void) testSimpleConflict
{
	NSArray *array2 = A(@"c");
	NSArray *array1 = A(@"a");
	NSArray *array3 = A(@"b");
	
	/**
	 * modify a->c
	 */
	COArrayDiff *diff12 = [[COArrayDiff alloc] initWithFirstArray: array1 secondArray: array2 sourceIdentifier: @"diff12"];
	
	/**
	 * modify a->b
	 */
	COArrayDiff *diff13 = [[COArrayDiff alloc] initWithFirstArray: array1 secondArray: array3 sourceIdentifier: @"diff13"];
	
	COArrayDiff *merged = (COArrayDiff *)[diff12 sequenceDiffByMergingWithDiff: diff13];
	UKTrue([merged hasConflicts]);
	
	// Examine the {a->c, a->b} change group
	
	COOverlappingSequenceEditGroup *edit1 = (COOverlappingSequenceEditGroup *)[[merged operations] objectAtIndex: 0];
	
	UKObjectKindOf(edit1, COOverlappingSequenceEditGroup);
	UKTrue([edit1 hasConflicts]);
	UKIntsEqual(2, [[edit1 allEdits] count]);
	
	// Examine the a->c change from diff12
	
	NSArray *edit1diff12Array = [edit1 editsForSourceIdentifier: @"diff12"];
	UKIntsEqual(1, [edit1diff12Array count]);
	
	COSequenceModification *edit1diff12 = [edit1diff12Array objectAtIndex: 0];
	UKObjectKindOf(edit1diff12, COSequenceModification);
	UKObjectsEqual(A(@"c"), [edit1diff12 insertedObject]);
	UKTrue(NSEqualRanges(NSMakeRange(0, 1), [edit1diff12 range]));
	UKObjectsEqual(@"diff12", [edit1diff12 sourceIdentifier]);
	
	// Examine the a->b change from diff13
	
	NSArray *edit1diff13Array = [edit1 editsForSourceIdentifier: @"diff13"];
	UKIntsEqual(1, [edit1diff13Array count]);
	
	COSequenceModification *edit1diff13 = [edit1diff13Array objectAtIndex: 0];
	UKObjectKindOf(edit1diff13, COSequenceModification);
	UKObjectsEqual(A(@"b"), [edit1diff13 insertedObject]);
	UKTrue(NSEqualRanges(NSMakeRange(0, 1), [edit1diff13 range]));
	UKObjectsEqual(@"diff13", [edit1diff13 sourceIdentifier]);
	
	UKFalse([edit1diff12 isEqualIgnoringSourceIdentifier: edit1diff13]);
}

- (void) testLessSimpleConflict
{
	/*
	 
	 in this example, <delete 'b'-'d'> will conflict with two changes, {b->X, d->Z}
	 
	 */
	
	NSArray *array2 = A(@"a",                   @"e");
	NSArray *array1 = A(@"a", @"b", @"c", @"d", @"e");
	NSArray *array3 = A(@"a", @"X", @"c", @"Z", @"e");
	
	COArrayDiff *diff12 = [[COArrayDiff alloc] initWithFirstArray: array1 secondArray: array2 sourceIdentifier: @"diff12"];
	COArrayDiff *diff13 = [[COArrayDiff alloc] initWithFirstArray: array1 secondArray: array3 sourceIdentifier: @"diff13"];
	
	COArrayDiff *merged = (COArrayDiff *)[diff12 sequenceDiffByMergingWithDiff: diff13];
	UKTrue([merged hasConflicts]);
	UKIntsEqual(1, [[merged operations] count]);
	
	// Examine the (single) change group
	
	COOverlappingSequenceEditGroup *edit1 = (COOverlappingSequenceEditGroup *)[[merged operations] objectAtIndex: 0];
	
	UKObjectKindOf(edit1, COOverlappingSequenceEditGroup);
	UKTrue([edit1 hasConflicts]);
	
	// Examine the <delete 'b'-'d'> change from diff12
	
	NSArray *edit1diff12Array = [edit1 editsForSourceIdentifier: @"diff12"];
	UKIntsEqual(1, [edit1diff12Array count]);
	
	COSequenceDeletion *edit1diff12 = [edit1diff12Array objectAtIndex: 0];
	UKObjectKindOf(edit1diff12, COSequenceDeletion);
	UKTrue(NSEqualRanges(NSMakeRange(1, 3), [edit1diff12 range]));
	UKObjectsEqual(@"diff12", [edit1diff12 sourceIdentifier]);
	
	// Examine the {b->X, d->Z} change from diff13
	
	NSArray *edit1diff13Array = [edit1 editsForSourceIdentifier: @"diff13"];
	UKIntsEqual(2, [edit1diff13Array count]);
	
	COSequenceModification *edit1diff13_1 = [edit1diff13Array objectAtIndex: 0];
	UKObjectKindOf(edit1diff13_1, COSequenceModification);
	UKObjectsEqual(A(@"X"), [edit1diff13_1 insertedObject]);
	UKTrue(NSEqualRanges(NSMakeRange(1, 1), [edit1diff13_1 range]));
	UKObjectsEqual(@"diff13", [edit1diff13_1 sourceIdentifier]);
	
	COSequenceModification *edit1diff13_2 = [edit1diff13Array objectAtIndex: 1];
	UKObjectKindOf(edit1diff13_2, COSequenceModification);
	UKObjectsEqual(A(@"Z"), [edit1diff13_2 insertedObject]);
	UKTrue(NSEqualRanges(NSMakeRange(3, 1), [edit1diff13_2 range]));
	UKObjectsEqual(@"diff13", [edit1diff13_2 sourceIdentifier]);
}


#endif

@end
