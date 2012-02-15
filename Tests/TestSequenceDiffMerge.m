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
	
	COSequenceEdit *edit1 = [[merged operations] objectAtIndex: 0];
	
	UKFalse([edit1 hasConflicts]);
	UKIntsEqual(2, [[edit1 allEdits] count]);
	UKTrue(NSEqualRanges(NSMakeRange(0, 1), [[[[edit1 allEdits] allObjects] objectAtIndex: 0] range]));
	UKTrue(NSEqualRanges(NSMakeRange(0, 1), [[[[edit1 allEdits] allObjects] objectAtIndex: 1] range]));
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

	COSequenceEdit *edit1 = [[merged operations] objectAtIndex: 0];
}

@end
