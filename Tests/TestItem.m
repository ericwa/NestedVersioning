#import "TestCommon.h"

@interface TestItem : NSObject <UKTest> {
	
}

@end

@implementation TestItem

- (void) testBasic
{
	COMutableItem *i1 = [COMutableItem item];
	i1.schemaName = @"org.etoile.test";
    
	[i1 setValue: S(@"hello", @"world")
	forAttribute: @"contents"
			type: kCOStringType | kCOSetType];
	
	// test round trip to plist
	{
        NSString *err = nil;
		id plist = [NSPropertyListSerialization propertyListFromData:
					[NSPropertyListSerialization dataFromPropertyList: [i1 plist]
															   format: NSPropertyListXMLFormat_v1_0
													 errorDescription: &err]
													mutabilityOption: NSPropertyListMutableContainersAndLeaves
															  format: NULL
													errorDescription:NULL];
        
		COMutableItem *i1clone = [[[COMutableItem alloc] initWithPlist: plist] autorelease];
		UKObjectsEqual(i1, i1clone);
	}
    
    // test round trip to NSData
    {
		COMutableItem *i1clone = [[[COMutableItem alloc] initWithData: [i1 dataValue]] autorelease];
		UKObjectsEqual(i1, i1clone);        
    }
}

- (COItem *) roundTrip: (COItem *)anItem
{
    return [[[COMutableItem alloc] initWithData: [anItem dataValue]] autorelease];
}

- (void) testSchemaName
{
    COMutableItem *i1 = [COMutableItem item];
	i1.schemaName = nil;

    UKNil([[self roundTrip: i1] schemaName]);
    
    i1.schemaName = @"";
    UKObjectsEqual(@"", [[self roundTrip: i1] schemaName]);
    
    i1.schemaName = @"x";
    UKObjectsEqual(@"x", [[self roundTrip: i1] schemaName]);
}

- (void) testMutability
{	
	COItem *immutable = [COItem itemWithTypesForAttributes: D(kCOStringType | kCOSetType, @"key1",
															  kCOStringType | kCOArrayType, @"key2",
															  kCOStringType, @"name")
									   valuesForAttributes: D([NSMutableSet setWithObject: @"a"], @"key1",	
															  [NSMutableArray arrayWithObject: @"A"], @"key2",
															  @"my name", @"name")];

	UKRaisesException([(COMutableItem *)immutable setValue: @"foo" forAttribute: @"bar" type: kCOStringType]);

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
	COItem *immutable = [COItem itemWithTypesForAttributes: D([NSNumber numberWithInt: kCOStringType | kCOSetType], @"key1",
															  [NSNumber numberWithInt: kCOStringType | kCOArrayType], @"key2",
															  [NSNumber numberWithInt: kCOStringType], @"name")
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
	[item1 setValue: [NSSet set] forAttribute: @"set" type: kCOStringType | kCOSetType];
	
	COMutableItem *item2 = [COMutableItem item];
	
	UKObjectsNotEqual(item2, item1);
}

- (void) testBinaryExportForSetAttribute
{
	COMutableItem *item1 = [COMutableItem item];
	[item1 setValue: S(@"a", @"b", @"c") forAttribute: @"set" type: kCOStringType | kCOSetType];
		
	UKObjectsEqual(item1, [[[COItem alloc] initWithData: [item1 dataValue]] autorelease]);
}

- (void) testBinaryExportForArrayAttribute
{
	COMutableItem *item1 = [COMutableItem item];
	[item1 setValue: A(@"a", @"b", @"c") forAttribute: @"array" type: kCOStringType | kCOArrayType];
    
	UKObjectsEqual(item1, [[[COItem alloc] initWithData: [item1 dataValue]] autorelease]);
}


//- (void) testNamedType
//{
//	COMutableItem *item1 = [COMutableItem item];
//	item1 setValue: [NSSet set] forAttribute: @"set" type: [kCOStringType | kCOSetType namedType: @"testName"]];
//
//    UKObjectsEqual(@"testName", [[item1 typeForAttribute: @"set"] name]);
//}

@end