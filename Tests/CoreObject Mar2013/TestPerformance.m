#import "TestCommon.h"

@interface TestPerformance : COSQLiteStoreTestCase <UKTest>
@end

@implementation TestPerformance

- (COSchemaRegistry *) outlineSchemaRegistry
{
    COSchemaRegistry *reg = [COSchemaRegistry registry];
    
    COSchemaTemplate *schema = [COSchemaTemplate schemaWithName: @"OutlineItem"];
    [schema setType: kCOStringType forProperty: @"label"];
    
    [schema setType: kCOEmbeddedItemType | kCOSetType
         schemaName: @"OutlineItem"
        forProperty: @"contents"];
    
    [reg addSchema: schema];
    
    return reg;
}


- (void)testManyObjects
{
    NSDate *startDate = [NSDate date];
	
    COEditingContext *ctx = [COEditingContext editingContextWithSchemaRegistry: [self outlineSchemaRegistry]];
	COObject *root = [ctx insertObjectWithSchemaName: @"OutlineItem"];
    [ctx setRootObject: root];
    
	for (int i=0; i<10; i++)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		COObject *level1 = [ctx insertObjectWithSchemaName: @"OutlineItem"];
		[level1 setValue: [NSString stringWithFormat: @"%d", i] forAttribute: @"label"];
		[root addObject: level1 toUnorderedAttribute: @"contents"];
		for (int j=0; j<10; j++)
		{
			COObject *level2 = [ctx insertObjectWithSchemaName: @"OutlineItem"];
			[level2 setValue: [NSString stringWithFormat: @"%d.%d", i, j] forAttribute: @"label"];
			[level1 addObject: level2 toUnorderedAttribute: @"contents"];
			for (int k=0; k<10; k++)
			{
				COObject *level3 = [ctx insertObjectWithSchemaName: @"OutlineItem"];
				[level3 setValue: [NSString stringWithFormat: @"%d.%d.%d", i, j, k] forAttribute: @"label"];
				[level2 addObject: level3 toUnorderedAttribute: @"contents"];
			}
		}
		[pool release];
	}

    UKIntsEqual(1111, [[ctx allObjectUUIDs] count]);
    
    
    COPersistentRootState *proot = [store createPersistentRootWithInitialContents:  [ctx itemTree]
                                                                         metadata: nil];
    
    COItemTree *items = [store contentsForRevisionID: proot.currentBranchState.currentState];
    UKIntsEqual(1111, [[items itemUUIDs] count]);
    
	NSLog(@"TestPerformance took %lf ms", 1000.0 * [[NSDate date] timeIntervalSinceDate: startDate]);

	UKPass();
}

@end
