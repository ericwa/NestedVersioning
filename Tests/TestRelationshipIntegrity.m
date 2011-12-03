#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>
#import "COEditingContext.h"
#import "COContainer.h"
#import "COStore.h"
#import "TestCommon.h"

@interface TestRelationshipIntegrity : NSObject <UKTest>
{
}
@end

@implementation TestRelationshipIntegrity


- (void)testBasicRelationshipIntegrity
{
	COStore *store = [[COStore alloc] initWithURL: STORE_URL];
	COEditingContext *ctx = [[COEditingContext alloc] initWithStore: store];
	
	// Test one-to-many relationships
	
	COObject *o1 = [ctx insertObjectWithEntityName: @"Anonymous.COContainer"]; // See COObject.m for metamodel definition
	COObject *o2 = [ctx insertObjectWithEntityName: @"Anonymous.COContainer"];
	COObject *o3 = [ctx insertObjectWithEntityName: @"Anonymous.COContainer"];
	
	[o2 setValue: o1 forProperty: @"parentContainer"]; // should add o2 to o1's contents
	[o2 setValue: A(o3) forProperty: @"contents"]; // should set parentContainer of o3

	UKNil([o1 valueForProperty: @"parentContainer"]);
	UKObjectsEqual(A(o2), [o1 valueForProperty: @"contents"]);
	UKObjectsEqual(o1, [o2 valueForProperty: @"parentContainer"]);
	UKObjectsEqual(A(o3), [o2 valueForProperty: @"contents"]);
	UKObjectsEqual(o2, [o3 valueForProperty: @"parentContainer"]);
	UKObjectsEqual([NSArray array], [o3 valueForProperty: @"contents"]);
	
	
	// Test many-to-many relationships
	
	COObject *t1 = [ctx insertObjectWithEntityName: @"Anonymous.COCollection"]; // See COObject.m for metamodel definition
	COObject *t2 = [ctx insertObjectWithEntityName: @"Anonymous.COCollection"];
	COObject *t3 = [ctx insertObjectWithEntityName: @"Anonymous.COCollection"];
	
	[t1 addObject: o1 forProperty: @"contents"];
	[t2 addObject: o1 forProperty: @"contents"];
	
	UKObjectsEqual(S(t1, t2), [o1 valueForProperty: @"parentCollections"]);
	
	[o2 addObject: t2 forProperty: @"parentCollections"];
	[o2 addObject: t3 forProperty: @"parentCollections"];
	
	UKObjectsEqual(S(o1), [t1 valueForProperty: @"contents"]);
	UKObjectsEqual(S(o1, o2), [t2 valueForProperty: @"contents"]);
	UKObjectsEqual(S(o2), [t3 valueForProperty: @"contents"]);
	
	[ctx release];
	[store release];
	DELETE_STORE;
}

- (void)testRelationshipIntegrityForMove
{
	COStore *store = [[COStore alloc] initWithURL: STORE_URL];
	COEditingContext *ctx = [[COEditingContext alloc] initWithStore: store];
	
	COObject *o1 = [ctx insertObjectWithEntityName: @"Anonymous.COContainer"]; // See COObject.m for metamodel definition
	COObject *o2 = [ctx insertObjectWithEntityName: @"Anonymous.COContainer"];
	COObject *o3 = [ctx insertObjectWithEntityName: @"Anonymous.COContainer"];
	
	[o2 setValue: o1 forProperty: @"parentContainer"]; // should add o2 to o1's contents
	UKObjectsEqual(A(o2), [o1 valueForProperty: @"contents"]);
	UKObjectsEqual([NSArray array], [o3 valueForProperty: @"contents"]);
	[o2 setValue: o3 forProperty: @"parentContainer"]; // should add o2 to o3's contents, and remove o2 from o1
	UKObjectsEqual([NSArray array], [o1 valueForProperty: @"contents"]);
	UKObjectsEqual(A(o2), [o3 valueForProperty: @"contents"]);	

	// Check that removing an object from a group nullifys that object's parent group pointer
	
	[o3 removeObject: o2 forProperty: @"contents"];
	UKNil([o2 valueForProperty: @"parentContainer"]);
	
	// Now test moving by modifying the multivalued side of the relationship
	
	COContainer *o4 = [ctx insertObjectWithEntityName: @"Anonymous.COContainer"]; 
	COContainer *o5 = [ctx insertObjectWithEntityName: @"Anonymous.COContainer"];
	COContainer *o6 = [ctx insertObjectWithEntityName: @"Anonymous.COContainer"];	
	
	[o5 addObject: o4];
	[o6 addObject: o4]; // Should move o4 from o5 to o6
	UKObjectsEqual([NSArray array], [o5 contentArray]);
	UKObjectsEqual(A(o4), [o6 contentArray]);
	UKObjectsSame(o6, [o4 valueForProperty: @"parentContainer"]);
	
	[ctx release];
	[store release];
	DELETE_STORE;
}

- (void)testRelationshipIntegrityMarksDamage
{
	COStore *store = [[COStore alloc] initWithURL: STORE_URL];
	COEditingContext *ctx = [[COEditingContext alloc] initWithStore: store];
	
	COObject *o1 = [ctx insertObjectWithEntityName: @"Anonymous.COContainer"]; // See COObject.m for metamodel definition
	COObject *o2 = [ctx insertObjectWithEntityName: @"Anonymous.COContainer"];
	COObject *o3 = [ctx insertObjectWithEntityName: @"Anonymous.COContainer"];
	[ctx commit];
	
	UKFalse([ctx objectHasChanges: [o1 UUID]]);
	UKFalse([ctx objectHasChanges: [o2 UUID]]);
	UKFalse([ctx objectHasChanges: [o3 UUID]]);
			 
	[o2 setValue: o1 forProperty: @"parentContainer"]; // should add o2 to o1's contents
	UKTrue([ctx objectHasChanges: [o1 UUID]]);
	UKTrue([ctx objectHasChanges: [o2 UUID]]);
	UKFalse([ctx objectHasChanges: [o3 UUID]]);
	
	[ctx commit];
	UKFalse([ctx objectHasChanges: [o1 UUID]]);
	UKFalse([ctx objectHasChanges: [o2 UUID]]);
	UKFalse([ctx objectHasChanges: [o3 UUID]]);
	
	[o2 setValue: o3 forProperty: @"parentContainer"]; // should add o2 to o3's contents, and remove o2 from o1
	UKTrue([ctx objectHasChanges: [o1 UUID]]);
	UKTrue([ctx objectHasChanges: [o2 UUID]]);
	UKTrue([ctx objectHasChanges: [o3 UUID]]);
	
	[ctx commit];
	
	[o3 removeObject: o2 forProperty: @"contents"]; // should make o2's parentContainer nil
	UKFalse([ctx objectHasChanges: [o1 UUID]]);
	UKTrue([ctx objectHasChanges: [o2 UUID]]);
	UKTrue([ctx objectHasChanges: [o3 UUID]]);	

	[ctx release];
	[store release];
	DELETE_STORE;
}

- (void)testOneToOneRelationship
{
	COStore *store = [[COStore alloc] initWithURL: STORE_URL];
	COEditingContext *ctx = [[COEditingContext alloc] initWithStore: store];
	
	COObject *p1 = [ctx insertObjectWithEntityName: @"Anonymous.Person"]; // See TestCommon.m for metamodel definition
	COObject *p2 = [ctx insertObjectWithEntityName: @"Anonymous.Person"];
	COObject *p3 = [ctx insertObjectWithEntityName: @"Anonymous.Person"];
	
	UKNil([p1 valueForProperty: @"spouse"]);
	[p1 setValue: p2 forProperty: @"spouse"];
	UKObjectsEqual(p1, [p2 valueForProperty: @"spouse"]);
	UKObjectsEqual(p2, [p1 valueForProperty: @"spouse"]);	
	[p2 setValue: p3 forProperty: @"spouse"];
	UKNil([p1 valueForProperty: @"spouse"]);
	UKObjectsEqual(p2, [p3 valueForProperty: @"spouse"]);
	UKObjectsEqual(p3, [p2 valueForProperty: @"spouse"]);	
	
	[ctx release];
	[store release];
	DELETE_STORE;
}

- (void)testShoppingList
{
	COEditingContext *ctx = NewContext();
	
	COContainer *workspace = [ctx insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	COContainer *document1 = [ctx insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	COContainer *group1 = [ctx insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	COContainer *leaf1 = [ctx insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	COContainer *leaf2 = [ctx insertObjectWithEntityName: @"Anonymous.OutlineItem"];	
	COContainer *group2 = [ctx insertObjectWithEntityName: @"Anonymous.OutlineItem"];	
	COContainer *leaf3 = [ctx insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	
	COContainer *document2 = [ctx insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	
	// Set up the initial state
	[document1 setValue:@"Document 1" forProperty: @"label"];
	[group1 setValue:@"Group 1" forProperty: @"label"];
	[leaf1 setValue:@"Leaf 1" forProperty: @"label"];
	[leaf2 setValue:@"Leaf 2" forProperty: @"label"];
	[group2 setValue:@"Group 2" forProperty: @"label"];
	[leaf3 setValue:@"Leaf 3" forProperty: @"label"];
	[document2 setValue:@"Document 2" forProperty: @"label"];
	
	[workspace addObject: document1];
	[workspace addObject: document2];
	[document1 addObject: group1];
	[group1 addObject: leaf1];
	[group1 addObject: leaf2];	
	[document1 addObject: group2];	
	[group2 addObject: leaf3];
	
	[ctx commit];
	// Now make some changes
	
	[group2 addObject: leaf2]; [ctx commit];
	[document2 addObject: group2]; [ctx commit];

	UKObjectsSame(workspace, [document1 valueForProperty: @"parentContainer"]);
	UKObjectsSame(workspace, [document2 valueForProperty: @"parentContainer"]);	
	UKObjectsSame(document1, [group1 valueForProperty: @"parentContainer"]);	
	UKObjectsSame(document2, [group2 valueForProperty: @"parentContainer"]);	
	UKObjectsSame(group1, [leaf1 valueForProperty: @"parentContainer"]);	
	UKObjectsSame(group2, [leaf2 valueForProperty: @"parentContainer"]);	
	UKObjectsSame(group2, [leaf3 valueForProperty: @"parentContainer"]);	
	UKObjectsEqual(S(document1, document2), [NSSet setWithArray: [workspace contentArray]]);
	UKObjectsEqual(S(group1), [NSSet setWithArray: [document1 contentArray]]); //fails
	UKObjectsEqual(S(group2), [NSSet setWithArray: [document2 contentArray]]);
	UKObjectsEqual(S(leaf1), [NSSet setWithArray: [group1 contentArray]]); //fails
	UKObjectsEqual(S(leaf2, leaf3), [NSSet setWithArray: [group2 contentArray]]);
	
	TearDownContext(ctx);
}

@end
