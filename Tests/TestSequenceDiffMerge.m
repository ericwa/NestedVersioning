#import "TestCommon.h"
#import "COSequenceDiff.h"

@interface TestSequenceDiffMerge : NSObject <UKTest>
{
}

@end

@implementation TestSequenceDiffMerge

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

@end
