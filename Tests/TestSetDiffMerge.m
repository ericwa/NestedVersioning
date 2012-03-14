#import "TestCommon.h"

@interface TestSetDiffMerge : NSObject <UKTest>
{
}

@end

@implementation TestSetDiffMerge

/*
- (void) testBasic
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

@end
