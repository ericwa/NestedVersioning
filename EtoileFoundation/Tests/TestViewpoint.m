/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>
#import "Macros.h"
#import "ETCollection+HOM.h"
#import "ETCollectionViewpoint.h"
#import "ETIndexValuePair.h"
#import "ETMutableObjectViewpoint.h"
#import "ETKeyValuePair.h"
#import "ETUnionViewpoint.h"
#import "NSObject+Model.h"
#import "EtoileCompatibility.h"

#define SA(x) [NSSet setWithArray: x]

@interface ImmutableObjectMutableViewpointTrait : NSObject
@end

@interface ImmutableObject : NSObject <ETViewpointMutation>
{
	NSNumber *characteristic;
}
+ (Class) mutableViewpointClass;
- (id) initWithCharacteristic: (NSNumber *)aCharacteristic;
@property (nonatomic, readonly) NSNumber *characteristic;
@end

@implementation ImmutableObject

+ (Class) mutableViewpointClass
{
	return [ImmutableObjectMutableViewpointTrait class];
}

- (id) initWithCharacteristic: (NSNumber *)aCharacteristic
{
	SUPERINIT;
	ASSIGN(characteristic, aCharacteristic);
	return self;
}

- (void) dealloc
{
	DESTROY(characteristic);
	[super dealloc];
}

- (NSNumber *) characteristic
{
	return characteristic;
}

- (NSArray *) propertyNames
{
	return [[super propertyNames] arrayByAddingObject: @"characteristic"];
}

@end

@interface Person : NSObject
{
	NSString *_name;
	NSDictionary *_emails;
	NSArray *_groupNames;
	ImmutableObject *_object;
}
@property (nonatomic, retain) NSString *name;
@property (nonatomic, copy) NSDictionary *emails;
@property (nonatomic, retain) NSArray *groupNames;
@property (nonatomic, retain) ImmutableObject *object;
@end

@implementation Person

@synthesize name = _name, emails = _emails, groupNames = _groupNames, object = _object;

- (id) init
{
	SUPERINIT;
	ASSIGN(_name, @"John");
	ASSIGN(_emails, D(@"john@etoile.com", @"Work", @"john@nowhere.org", @"Home"));
	ASSIGN(_groupNames, A(@"Somebody", @"Nobody"));
	return self;
}

- (void) dealloc
{
	DESTROY(_name);
	DESTROY(_emails);
	DESTROY(_groupNames);
	[super dealloc];
}

// TODO: ETCollectionViewpoint should report missing names in -propertyNames
- (NSArray *) propertyNames
{
	return [[super propertyNames]
		arrayByAddingObjectsFromArray: A(@"name", @"emails", @"groupNames", @"object")];
}

@end

@interface TestCollectionViewpoint : NSObject <UKTest>
{
	Person *person;
	id emails;
	id groupNames;
}

@end

@implementation TestCollectionViewpoint

- (id) init
{
	SUPERINIT;
	person = [Person new];
	emails = [[ETCollectionViewpoint alloc] initWithName: @"emails" representedObject: person];
	groupNames = [[ETCollectionViewpoint alloc] initWithName: @"groupNames" representedObject: person];
	return self;
}

- (void) dealloc
{
	DESTROY(person);
	DESTROY(emails);
	DESTROY(groupNames);
	[super dealloc];
}

- (void) testViewpoint
{
	UKTrue([[ETKeyValuePair pairWithKey: @"unknown" value: nil] isViewpoint]);
	ETIndexValuePair *pair = AUTORELEASE([[ETIndexValuePair alloc]
		initWithIndex: 0 value: nil representedObject: nil]);
	UKTrue([pair isViewpoint]);
	UKTrue([[ETMutableObjectViewpoint viewpointWithName: @"unknown" representedObject: nil] isViewpoint]);
	UKTrue([[ETCollectionViewpoint viewpointWithName: @"unknown" representedObject: nil] isViewpoint]);
	UKTrue([[ETUnionViewpoint viewpointWithName: @"unknown" representedObject: nil] isViewpoint]);
}

- (void) testKeyValuePairPropertyNames
{
	ETKeyValuePair *pair = [[emails viewpointArray] firstObject];
	
	UKTrue([[pair propertyNames] containsCollection: S(@"self", @"key", @"value")]);
}

- (void) testKeyValuePairPropertyNamesForNilValue
{
	ETKeyValuePair *pair = [ETKeyValuePair pairWithKey: @"unknown" value: nil];
	
	UKObjectsEqual(A(@"self", @"key", @"value"), [pair propertyNames]);
}

- (void) testIndexValuePairPropertyNames
{
	ETIndexValuePair *pair = [[groupNames viewpointArray] firstObject];
	
	UKTrue([[pair propertyNames] containsCollection: S(@"self", @"index", @"value")]);
}

- (void) testPropertyNames
{
	NSSet *dictViewpointProperties =
		SA([[[NSDictionary dictionary] propertyNames] arrayByAddingObject: @"value"]);
	NSSet *arrayViewpointProperties =
		SA([[[NSArray array] propertyNames] arrayByAddingObject: @"value"]);

	UKObjectsEqual(dictViewpointProperties, SA([emails propertyNames]));
	UKObjectsEqual(arrayViewpointProperties, SA([groupNames propertyNames]));
}

- (void) testPropertyNamesForNilValue
{
	[emails setValue: nil];
	[groupNames setValue: nil];

	UKNil([emails value]);
	UKNil([groupNames value]);
	UKObjectsEqual(A(@"self", @"value"), [emails propertyNames]);
	UKObjectsEqual(A(@"self", @"value"), [groupNames propertyNames]);
}

- (void) testValueForProperty
{
	UKIntsEqual([[person emails] count], [[emails valueForProperty: @"count"] unsignedIntegerValue]);
	UKIntsEqual([[person groupNames] count], [[groupNames valueForProperty: @"count"] unsignedIntegerValue]);
	UKObjectsSame([[person groupNames] lastObject], [groupNames valueForProperty: @"lastObject"]);
}

- (void) testContent
{
	UKObjectsEqual([person emails], [emails content]);
	UKObjectsEqual([person groupNames], [groupNames content]);
}

- (void) testAddition
{
	[emails addObject: @"john@random.co.uk"];
	[groupNames addObject: @"Elsewhere"];
	
	UKTrue([[person emails] containsObject: @"john@random.co.uk"]);
	UKObjectsEqual(@"Elsewhere", [[person groupNames] lastObject]);
}

- (void) testInsertion
{
	NSUInteger oldEmailCount = [emails count];
	ETKeyValuePair *pair =  [ETKeyValuePair pairWithKey: @"Personal" value: @"john@random.co.uk"];

	[emails insertObject: [pair value] atIndex: 1 hint: pair];
	[groupNames insertObject: @"Elsewhere" atIndex: 1 hint: nil];
	
	UKTrue([[[person emails] arrayRepresentation] containsObject: pair]);
	UKIntsEqual(oldEmailCount + 1, [[person emails] count]);
	UKObjectsEqual(A(@"Somebody", @"Elsewhere", @"Nobody"), [person groupNames]);
}

- (void) testRemoval
{
	NSUInteger oldEmailCount = [emails count];
	ETKeyValuePair *pair =  [ETKeyValuePair pairWithKey: @"Work" value: nil];
	
	[emails removeObject: [pair value] atIndex: 1 hint: pair];
	[groupNames removeObject: nil atIndex: 1 hint: nil];
	
	UKNil([[person emails] objectForKey: [pair key]]);
	UKIntsEqual(oldEmailCount - 1, [[person emails] count]);
	UKObjectsEqual(A(@"Somebody"), [person groupNames]);
}
		   
- (void) testValueRemoval
{
	[emails removeObject: @"john@etoile.com"];
	[groupNames removeObject: @"Somebody"];
	
	UKNil([[person emails] objectForKey: @"Work"]);
	UKObjectsEqual(A(@"Nobody"), [person groupNames]);
}

@end


@interface TestUnionViewpoint : NSObject <UKTest>
{
	NSMutableArray *persons;
	ETUnionViewpoint *viewpoint;
}

@end

@implementation TestUnionViewpoint

- (id) init
{
	SUPERINIT;
	
	Person *john = AUTORELEASE([Person new]);
	Person *julie = AUTORELEASE([Person new]);

	[john setName: @"John"];
	[john setEmails: D(@"john@etoile.com", @"Work", @"john@nowhere.org", @"Home")];
	[john setObject: AUTORELEASE([[ImmutableObject alloc]
		initWithCharacteristic: [NSNumber numberWithInt: 10]])];
	[julie setName: @"Julie"];
	[julie setObject: AUTORELEASE([[ImmutableObject alloc]
		initWithCharacteristic: [NSNumber numberWithInt: 20]])];

	persons = [A(john, julie) mutableCopy];
	[[persons mappedCollection] setGroupNames: A(@"Somebody", @"Nobody")];

	viewpoint = [[ETUnionViewpoint alloc] initWithName: @"self" representedObject: persons];
	return self;
}

- (void) dealloc
{
	DESTROY(persons);
	DESTROY(viewpoint);
	[super dealloc];
}

- (void) testKeyValueCodingForUnionOperator
{
	NSArray *allGroupNames = [persons valueForKeyPath: @"@distinctUnionOfArrays.groupNames"];
	
	UKObjectsEqual(allGroupNames, [[persons lastObject] valueForKeyPath: @"groupNames"]);
}

- (void) testValueForProperty
{
	UKObjectsEqual([[viewpoint class] mixedValueMarker], [viewpoint valueForProperty: @"name"]);
	UKObjectsEqual(A(@"Somebody", @"Nobody"), [viewpoint valueForProperty: @"groupNames"]);
	UKNil([viewpoint valueForProperty: @"missing"]);
}

- (void) testContentKey
{
	[viewpoint setContentKeyPath: @"name"];

	UKObjectsEqual(A(@"John", @"Julie"), [viewpoint content]);
	UKObjectsEqual([[viewpoint class] mixedValueMarker], [viewpoint value]);
	UKObjectsEqual([viewpoint value], [viewpoint valueForProperty: @"value"]);
	UKObjectsEqual([[viewpoint class] mixedValueMarker], [viewpoint valueForProperty: @"self"]);
	UKTrue([[viewpoint valueForProperty: @"class"] isSubclassOfClass: [NSString class]]);
	UKNil([viewpoint valueForProperty: @"missing"]);
}

- (void) testCollectionOperator
{
	[viewpoint setContentKeyPath: @"@distinctUnionOfArrays.groupNames"];

	UKObjectsEqual(A(A(@"Somebody", @"Nobody"), A(@"Somebody", @"Nobody")), [viewpoint content]);
	UKObjectsEqual(A(@"Somebody", @"Nobody"), [viewpoint value]);
	UKObjectsEqual([viewpoint value], [viewpoint valueForProperty: @"value"]);
	UKObjectsEqual(A(@"Somebody", @"Nobody"), [viewpoint valueForProperty: @"self"]);
	UKTrue([[viewpoint valueForProperty: @"class"] isSubclassOfClass: [NSArray class]]);
	UKNil([viewpoint valueForProperty: @"missing"]);
}

- (void) testContentKeyPath
{
	[viewpoint setContentKeyPath: @"object"];

	UKObjectsEqual([[persons mappedCollection] object], [viewpoint content]);
	/* The two objects are not equal */
	UKObjectsEqual([[viewpoint class] mixedValueMarker], [viewpoint value]);
	UKObjectsEqual([viewpoint value], [viewpoint valueForProperty: @"value"]);
	UKObjectsEqual([[viewpoint class] mixedValueMarker], [viewpoint valueForProperty: @"characteristic"]);
	UKTrue([[viewpoint valueForProperty: @"class"] isSubclassOfClass: [ImmutableObject class]]);
	UKNil([viewpoint valueForProperty: @"missing"]);

	[viewpoint setContentKeyPath: @"object.characteristic"];
	
	NSArray *characteristics = A([NSNumber numberWithInt: 10], [NSNumber numberWithInt: 20]);

	UKObjectsEqual(characteristics, [viewpoint content]);
	UKObjectsEqual([[viewpoint class] mixedValueMarker], [viewpoint value]);
	UKObjectsEqual([viewpoint value], [viewpoint valueForProperty: @"value"]);
	UKObjectsEqual([[viewpoint class] mixedValueMarker], [viewpoint valueForProperty: @"self"]);
	UKTrue([[viewpoint valueForProperty: @"class"] isSubclassOfClass: [NSNumber class]]);
	UKNil([viewpoint valueForProperty: @"missing"]);
}

- (void) testValueChangeInContentKeyPath
{
	[viewpoint setContentKeyPath: @"object.characteristic"];
	ImmutableObject *object = AUTORELEASE([[ImmutableObject alloc]
		initWithCharacteristic: [NSNumber numberWithInt: 30]]);
	[(Person *)[persons mappedCollection] setObject: object];

	UKObjectsEqual([NSNumber numberWithInt: 30], [viewpoint valueForProperty: @"self"]);
}

- (void) testCollectionChangeInContentKeyPath
{
	[viewpoint setContentKeyPath: @"object.characteristic"];
	[persons addObject: AUTORELEASE([Person new])];

	UKObjectsEqual([[viewpoint class] mixedValueMarker], [viewpoint valueForProperty: @"self"]);
}

@end


@interface TestMutableObjectViewpoint : NSObject <UKTest>
{
	Person *person;
	ETMutableObjectViewpoint *object;
}

@end

@implementation TestMutableObjectViewpoint

- (id) init
{
	SUPERINIT;
	person = [Person new];
	[person setObject: AUTORELEASE([[ImmutableObject alloc]
		initWithCharacteristic: [NSNumber numberWithInt: 10]])];
	object = [[ETMutableObjectViewpoint alloc] initWithName: @"object" representedObject: person];
	return self;
}

- (void) dealloc
{
	DESTROY(person);
	DESTROY(object);
	[super dealloc];
}

- (void) testIsMutableValue
{
	UKFalse([object isMutableValue]);
}

- (void) testViewpointClass
{
	UKObjectKindOf(object, ETMutableObjectViewpoint);
}

- (void) testPropertyNames
{
	NSSet *viewpointProperties = SA([[AUTORELEASE([ImmutableObject new]) propertyNames]
		arrayByAddingObject: @"value"]);

	UKObjectsEqual(viewpointProperties, SA([object propertyNames]));
}

- (void) testPropertyNamesForNilValue
{
	[object setValue: nil];

	UKNil([object value]);
	UKObjectsEqual(A(@"self", @"value"), [object propertyNames]);
}

- (void) testValueForProperty
{
	UKObjectsEqual([[person object] characteristic], [object valueForProperty: @"characteristic"]);
	UKObjectsEqual([ImmutableObject class], [object valueForProperty: @"class"]);
	UKNil([object valueForProperty: @"missing"]);
}

- (void) testSetValueForProperty
{
	NSNumber *characteristic = [NSNumber numberWithInt: 3];

	UKObjectsNotEqual(characteristic, [[person object] characteristic]);

	[object setValue: characteristic forProperty: @"characteristic"];

	UKObjectsEqual(characteristic, [[person object] characteristic]);
	UKObjectsEqual([object value], [person object]);

	[object setValue: characteristic forProperty: @"missing"];
	
	UKNil([[person object] valueForProperty: @"missing"]);
	UKObjectsEqual([object value], [person object]);
}

@end

@implementation ImmutableObjectMutableViewpointTrait

- (void) setCharacteristic: (NSNumber *)aCharacteristic
{
	ImmutableObject *newObject =
		AUTORELEASE([[ImmutableObject alloc] initWithCharacteristic: aCharacteristic]);
	[self setValue: newObject];
}

@end
