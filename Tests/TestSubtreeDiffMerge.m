#import "TestCommon.h"
#import "COItemDiff.h"

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
	COSubtreeDiff *diff_t1_u1 = [COSubtreeDiff diffSubtree: t1 withSubtree: u1];
	
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
