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
	
	
	// Now do the merge
	
	
	/*
	COObjectGraphDiff *diff_ctx3_vs_ctx2 = [COObjectGraphDiff diffContainer: (id)[ctx3 objectWithUUID: [doc UUID]]
															  withContainer: (id)[ctx2 objectWithUUID: [doc UUID]]];
	UKNotNil(diff_ctx3_vs_ctx2);
	
	COObjectGraphDiff *diff_ctx3_vs_ctx1 = [COObjectGraphDiff diffContainer: (id)[ctx3 objectWithUUID: [doc UUID]]
															  withContainer: (id)[ctx1 objectWithUUID: [doc UUID]]];
	UKNotNil(diff_ctx3_vs_ctx2);
	
	
	COObjectGraphDiff *merged = [COObjectGraphDiff mergeDiff: diff_ctx3_vs_ctx2
													withDiff: diff_ctx3_vs_ctx1];
	// FIXME: Test that there are no conflicts
	
	
	// Apply the resulting diff to ctx3
	UKFalse([ctx1 hasChanges]);
	[merged applyToContext: ctx3];
	
	UKIntsEqual(5, [[(COContainer *)[ctx3 objectWithUUID: [doc UUID]] contentArray] count]);
	if (5 == [[doc contentArray] count])
	{
		UKStringsEqual(@"triangle1", [[[(COContainer *)[ctx3 objectWithUUID: [doc UUID]] contentArray] objectAtIndex: 0] valueForProperty: @"label"]);
		UKStringsEqual(@"line1", [[[(COContainer *)[ctx3 objectWithUUID: [doc UUID]] contentArray] objectAtIndex: 1] valueForProperty: @"label"]);
		UKStringsEqual(@"circle1", [[[(COContainer *)[ctx3 objectWithUUID: [doc UUID]] contentArray] objectAtIndex: 2] valueForProperty: @"label"]);
		UKStringsEqual(@"square1", [[[(COContainer *)[ctx3 objectWithUUID: [doc UUID]] contentArray] objectAtIndex: 3] valueForProperty: @"label"]);	
		UKStringsEqual(@"image1", [[[(COContainer *)[ctx3 objectWithUUID: [doc UUID]] contentArray] objectAtIndex: 4] valueForProperty: @"label"]);
	}
	
	for (COContainer *object in [(COContainer *)[ctx3 objectWithUUID: [doc UUID]] contentArray])
	{
		UKObjectsSame([ctx3 objectWithUUID: [doc UUID]], [object valueForProperty: @"parentContainer"]);
	}*/
}


@end
