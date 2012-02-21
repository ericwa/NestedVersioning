#import "TestCommon.h"

@interface TestObjectGraphDiff : NSObject <UKTest>
{
}

@end

@implementation TestObjectGraphDiff

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
	
	[doc addObject: line1 toOrderedAttribute: @"contents" type: [COType uniqueArrayWithPrimitiveType: [COType embeddedItemType]]];
	[doc addObject: circle1 toOrderedAttribute: @"contents" type: [COType uniqueArrayWithPrimitiveType: [COType embeddedItemType]]];
	[doc addObject: square1 toOrderedAttribute: @"contents" type: [COType uniqueArrayWithPrimitiveType: [COType embeddedItemType]]];
	[doc addObject: image1 toOrderedAttribute: @"contents" type: [COType uniqueArrayWithPrimitiveType: [COType embeddedItemType]]];
	
	
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
	
	COSubtreeDiff *diff_doc3_vs_doc2 = [COSubtreeDiff diffSubtree: doc3 withSubtree: doc2];
	COSubtreeDiff *diff_doc3_vs_doc = [COSubtreeDiff diffSubtree: doc3 withSubtree: doc];

	// Sanity check that the diffs work
	
	UKObjectsEqual(doc, [diff_doc3_vs_doc subtreeWithDiffAppliedToSubtree: doc3]);
	UKObjectsEqual(doc2, [diff_doc3_vs_doc2 subtreeWithDiffAppliedToSubtree: doc3]);
	
	COSubtreeDiff *diff_merged = [COSubtreeDiff mergeDiff: diff_doc3_vs_doc2
												withDiff: diff_doc3_vs_doc];

	// FIXME: Test that there are no conflicts
	
	COSubtree *merged = [diff_merged subtreeWithDiffAppliedToSubtree: doc3];
	
	UKIntsEqual(5, [[doc3 valueForAttribute: @"contents"] count]);
	if (5 == [[doc3 valueForAttribute: @"contents"] count])
	{
		UKStringsEqual(@"triangle1", [[[doc3 valueForAttribute: @"contents"] objectAtIndex: 0] valueForAttribute: @"label"]);
		UKStringsEqual(@"line1", [[[doc3 valueForAttribute: @"contents"] objectAtIndex: 1] valueForAttribute: @"label"]);
		UKStringsEqual(@"circle1", [[[doc3 valueForAttribute: @"contents"] objectAtIndex: 2] valueForAttribute: @"label"]);
		UKStringsEqual(@"square1", [[[doc3 valueForAttribute: @"contents"] objectAtIndex: 3] valueForAttribute: @"label"]);	
		UKStringsEqual(@"image1", [[[doc3 valueForAttribute: @"contents"] objectAtIndex: 4] valueForAttribute: @"label"]);
	}
}


@end