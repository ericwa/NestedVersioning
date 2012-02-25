#import "TestCommon.h"
#import "COType.h"
#import "COItemPath.h"
#import "COSubtreeDiff.h"

@interface TestItem : NSObject <UKTest> {
	
}

@end

@implementation TestItem

- (void) testBasic
{
	COMutableItem *i1 = [COMutableItem item];
	
	COPath *p1 = [[[COPath path]
				   pathByAppendingPathComponent:[ETUUID UUIDWithString: @"cdf68e39-8f4b-4afa-9f81-ba2f7cdf50e6"]]
				  pathByAppendingPathComponent:[ETUUID UUIDWithString: @"8a099b84-09eb-4a3e-828d-9a897778e5e3"]];
	
	[i1 setValue: S(p1)
	forAttribute: @"contents"
			type: [COType setWithPrimitiveType: [COType pathType]]];
	
	// test round trip to plist
	{
		id plist = [NSPropertyListSerialization propertyListFromData:
					[NSPropertyListSerialization dataFromPropertyList: [i1 plist]
															   format:NSPropertyListXMLFormat_v1_0
													 errorDescription:NULL]
													mutabilityOption: NSPropertyListMutableContainersAndLeaves
															  format: NULL
													errorDescription:NULL];
		COMutableItem *i1clone = [[[COMutableItem alloc] initWithPlist: plist] autorelease];
		UKObjectsEqual(i1, i1clone);
	}
}

- (void) testConsistency
{
	ETUUID *u1 = [ETUUID UUID];
	
	// It is illegal to have the same embedded item in two places.
	
	UKRaisesException([COItem itemWithTypesForAttributes: D([COType embeddedItemType], @"key1",
															[COType embeddedItemType], @"key2")
									 valuesForAttributes: D(u1, @"key1",	
															u1, @"key2")]);

	UKRaisesException({
		COMutableItem *i1 = [COMutableItem item];
		[i1 setValue: u1 forAttribute: @"key1" type: [COType embeddedItemType]];
		[i1 setValue: u1 forAttribute: @"key2" type: [COType embeddedItemType]];
	});
	
	
	// It is illegal to create an embedded item collection which allows duplicates
	
	UKRaisesException([COItem itemWithTypesForAttributes: D([COType bagWithPrimitiveType: [COType embeddedItemType]], @"key1")
									 valuesForAttributes: D([NSCountedSet setWithObject: u1], @"key1")]);

	UKRaisesException([COItem itemWithTypesForAttributes: D([COType arrayWithPrimitiveType: [COType embeddedItemType]], @"key1")
									 valuesForAttributes: D(A(u1), @"key1")]);
	
	
	// Test setting objects of the wrong type
	
	UKRaisesException({
		COMutableItem *i1 = [COMutableItem item];
		[i1 setValue: S(u1) forAttribute: @"key1" type: [COType arrayWithPrimitiveType: [COType embeddedItemType]]];
	});
	UKRaisesException({
		COMutableItem *i1 = [COMutableItem item];
		[i1 setValue: A(u1) forAttribute: @"key1" type: [COType setWithPrimitiveType: [COType embeddedItemType]]];
	});
	
	// Test an item which contains itself
	
	UKRaisesException([[[COItem alloc] initWithUUID: u1
								 typesForAttributes: D([COType embeddedItemType], @"key1")
								valuesForAttributes: D(u1, @"key1")] autorelease]);
	
	UKRaisesException({
		COMutableItem *i1 = [[[COMutableItem alloc] initWithUUID: u1] autorelease];
		[i1 setValue: u1 forAttribute: @"key1" type: [COType embeddedItemType]];
	});
}

@end