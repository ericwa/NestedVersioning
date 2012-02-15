#import "TestCommon.h"

@interface TestSequenceDiffMerge : NSObject <UKTest>
{
}

@end

@implementation TestSequenceDiffMerge

- (void) testBasic
{
	NSArray *array2 = A(@"A", @"c", @"d", @"zoo", @"e");
	NSArray *array1 = A(@"a", @"b", @"c", @"d", @"e", @"f");
	NSArray *array3 = A(@"A", @"b", @"c", @"e", @"foo");
	
	/**
	 * a->A, remove b, insert 'zoo' after d, remove f
	 */
	COArrayDiff *diff12 = [[COArrayDiff alloc] initWithFirstArray: array1 secondArray: array2 sourceIdentifier: @"diff12"];
	COArrayDiff *diff13 = [[COArrayDiff alloc] initWithFirstArray: array1 secondArray: array3 sourceIdentifier: @"diff13"];
	
	UKObjectsEqual(array2, [diff12 arrayWithDiffAppliedTo: array1]);
	UKObjectsEqual(array3, [diff13 arrayWithDiffAppliedTo: array1]);
	
	COArrayDiff *merged = (COArrayDiff *)[diff12 sequenceDiffByMergingWithDiff: diff13];
	NSLog(@"Merge result: %@", merged);
	// FIXME: test the merge result
	//NSLog(@"Expected: a->A, remove b, delete d, insert 'zoo' after d, insert foo after e");

}

@end
