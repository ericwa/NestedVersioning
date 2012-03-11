#import "TestCommon.h"

#if 0
@interface TestItemDiffMerge : NSObject <UKTest>
{
}

@end

@implementation TestItemDiffMerge

- (void) testBasic
{
	COItem *i1 = [COItem itemWithTypesForAttributes: D([COType stringType], @"type",
													   [COType setWithPrimitiveType: [COType stringType]], @"places")
								valuesForAttributes: D(@"test", @"type",
													   S(@"home"), @"places")];
	
	COItem *i2 = [COItem itemWithTypesForAttributes: D([COType stringType], @"name",
													   [COType setWithPrimitiveType: [COType stringType]], @"places")
						   valuesForAttributes: D(@"hello", @"name",
												  S(@"work", @"home"), @"places")];
	
	COItemDiff *diff = [COItemDiff diffItem: i1 withItem: i2];
	COItem *i2_fromDiff = [diff itemWithDiffAppliedTo: i1];
	
	UKObjectsEqual(i2, i2_fromDiff);
}

- (void)testSelectiveUndoOfGroupOperation
{
	// snapshot the state: (line1, circle1, square1, image1) into doc2
	
	ETUUID *u1 = [ETUUID UUID];
	
	COItem *doc2 = [[COItem alloc] initWithUUID: u1
							 typesForAttributes: D([COType arrayWithPrimitiveType: [COType stringType]], @"objects")
							valuesForAttributes: D(A(@"line1", @"circle1", @"square1", @"image1"), @"objects")];
		
	// snapshot the state:  (line1, group1, image1) into doc3

	COItem *doc3 = [[COItem alloc] initWithUUID: u1
							 typesForAttributes: D([COType arrayWithPrimitiveType: [COType stringType]], @"objects")
							valuesForAttributes: D(A(@"line1", @"group1", @"image1"), @"objects")];
							
	// doc1 state:  (triangl1, line1, group1, image1)

	COItem *doc = [[COItem alloc] initWithUUID: u1
							typesForAttributes: D([COType arrayWithPrimitiveType: [COType stringType]], @"objects")
						   valuesForAttributes: D(A(@"triangle1", @"line1", @"group1", @"image1"), @"objects")];
	
	// ------------
	
	// Calculate diffs
	
	COItemDiff *diff_doc3_vs_doc2 = [COItemDiff diffItem: doc3 withItem: doc2];
	COItemDiff *diff_doc3_vs_doc = [COItemDiff diffItem: doc3 withItem: doc];
	
	// Sanity check that the diffs work
	
	UKObjectsEqual(doc, [diff_doc3_vs_doc itemWithDiffAppliedTo: doc3]);
	UKObjectsEqual(doc2, [diff_doc3_vs_doc2 itemWithDiffAppliedTo: doc3]);
	
	COItemDiff *diff_merged = [diff_doc3_vs_doc2 itemDiffByMergingWithDiff: diff_doc3_vs_doc];
	
	UKFalse([diff_merged hasConflicts]);
	
	COItem *merged = [diff_merged itemWithDiffAppliedTo: doc3];
	
	UKObjectsEqual(A(@"triangle1", @"line1", @"circle1", @"square1", @"image1"), [merged valueForAttribute: @"objects"]);
	
	[doc release];
	[doc2 release];
	[doc3 release];
}

- (void)testConflict
{
	ETUUID *u1 = [ETUUID UUID];
	ETUUID *u2 = [ETUUID UUID];
	
	COItem *i1 = [[COMutableItem alloc] initWithUUID: u1];
	COItem *i2 = [[COItem alloc] initWithUUID: u1
						   typesForAttributes: D([COType setWithPrimitiveType: [COType embeddedItemType]], @"key1")
						  valuesForAttributes: D(S(u2), @"key1")];
	COItem *i3 = [[COItem alloc] initWithUUID: u1
						   typesForAttributes: D([COType setWithPrimitiveType: [COType embeddedItemType]], @"key2")
						  valuesForAttributes: D(S(u2), @"key2")];
	
	// ------------
	
	// Calculate diffs
	
	COItemDiff *diff_i1_i2 = [COItemDiff diffItem: i1 withItem: i2];
	COItemDiff *diff_i1_i3 = [COItemDiff diffItem: i1 withItem: i3];
	
	// Sanity check that the diffs work
	
	UKObjectsEqual(i2, [diff_i1_i2 itemWithDiffAppliedTo: i1]);
	UKObjectsEqual(i3, [diff_i1_i3 itemWithDiffAppliedTo: i1]);
	
	COItemDiff *diff_merged = [diff_i1_i2 itemDiffByMergingWithDiff: diff_i1_i3];
	
	UKTrue([diff_merged hasConflicts]);

	// FIXME: ...
	
	[i1 release];
	[i2 release];
	[i3 release];
}

@end

#endif
