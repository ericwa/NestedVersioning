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
				   pathByAppendingPathComponent:[COUUID UUIDWithString: @"cdf68e39-8f4b-4afa-9f81-ba2f7cdf50e6"]]
				  pathByAppendingPathComponent:[COUUID UUIDWithString: @"8a099b84-09eb-4a3e-828d-9a897778e5e3"]];
	
	[i1 setValue: S(p1)
	forAttribute: @"contents"
			type: [[COType pathType] setType]];
	
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
	COUUID *u1 = [COUUID UUID];
	
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
	
	// Test setting objects of the wrong type
	
	UKRaisesException({
		COMutableItem *i1 = [COMutableItem item];
		[i1 setValue: S(u1) forAttribute: @"key1" type: [[COType embeddedItemType] setType]];
	});
	UKRaisesException({
		COMutableItem *i1 = [COMutableItem item];
		[i1 setValue: A(u1) forAttribute: @"key1" type: [[COType embeddedItemType] setType]];
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

- (void) testMutability
{	
	COItem *immutable = [COItem itemWithTypesForAttributes: D([[COType stringType] setType], @"key1",
															  [[COType stringType] arrayType], @"key2",
															  [COType stringType], @"name")
									   valuesForAttributes: D([NSMutableSet setWithObject: @"a"], @"key1",	
															  [NSMutableArray arrayWithObject: @"A"], @"key2",
															  @"my name", @"name")];

	UKRaisesException([(COMutableItem *)immutable setValue: @"foo" forAttribute: @"bar" type: [COType stringType]]);

	UKRaisesException([[immutable valueForAttribute: @"key1"] addObject: @"b"]);
	UKRaisesException([[immutable valueForAttribute: @"key2"] addObject: @"B"]);
	
	COMutableItem *mutable = [[immutable mutableCopy] autorelease];
	
	UKDoesNotRaiseException([[mutable valueForAttribute: @"key1"] addObject: @"b"]);
	UKDoesNotRaiseException([[mutable valueForAttribute: @"key2"] addObject: @"B"]);
	
	UKIntsEqual(1, [[immutable valueForAttribute: @"key1"] count]);
	UKIntsEqual(1, [[immutable valueForAttribute: @"key2"] count]);
	
	UKIntsEqual(2, [[mutable valueForAttribute: @"key1"] count]);
	UKIntsEqual(2, [[mutable valueForAttribute: @"key2"] count]);
	
	UKRaisesException([[mutable valueForAttribute: @"name"] appendString: @"xxx"]);
}

- (void) testEquality
{
	COItem *immutable = [COItem itemWithTypesForAttributes: D([[COType stringType] setType], @"key1",
															  [[COType stringType] arrayType], @"key2",
															  [COType stringType], @"name")
									   valuesForAttributes: D([NSMutableSet setWithObject: @"a"], @"key1",	
															  [NSMutableArray arrayWithObject: @"A"], @"key2",
															  @"my name", @"name")];
	COMutableItem *mutable = [[immutable mutableCopy] autorelease];
	
	UKObjectsEqual(immutable, mutable);
	UKObjectsEqual(mutable, immutable);
}

- (void) testEmptySet
{
	COMutableItem *item1 = [COMutableItem item];
	[item1 setValue: [NSSet set] forAttribute: @"set" type: [[COType stringType] setType]];
	
	COMutableItem *item2 = [COMutableItem item];
	
	UKObjectsNotEqual(item2, item1);
}

@end