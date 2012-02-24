#import "TestCommon.h"
#import "COItemDiff.h"

@interface TestItemDiffMerge : NSObject <UKTest>
{
}

@end

@implementation TestItemDiffMerge

- (void) testBasic
{
	COItem *i1 = [[[COItem alloc] initWithUUID: [ETUUID UUID]
							typesForAttributes: D([COType stringType], @"type",
												  [COType setWithPrimitiveType: [COType stringType]], @"places")
						   valuesForAttributes: D(@"test", @"type",
												  S(@"home"), @"places")] autorelease];
	
	
	COItem *i2 = [[[COItem alloc] initWithUUID: [ETUUID UUID]
							typesForAttributes: D([COType stringType], @"name",
												  [COType setWithPrimitiveType: [COType stringType]], @"places")
						   valuesForAttributes: D(@"hello", @"name",
												  S(@"work", @"home"), @"places")] autorelease];
	
	COItemDiff *diff = [COItemDiff diffItem: i1 withItem: i2];
	COItem *i2_fromDiff = [diff itemWithDiffAppliedTo: i1];
	
	UKObjectsEqual(i2, i2_fromDiff);
}

@end
