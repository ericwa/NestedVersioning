#import "TestCommon.h"
#import "COType.h"
#import "COItemPath.h"
#import "COSubtreeDiff.h"

@interface TestSubtree : NSObject <UKTest> {
	
}

@end

@implementation TestSubtree

- (void) testSubtreeBasic
{
	COSubtree *t1 = [COSubtree subtree];
	COSubtree *t2 = [COSubtree subtree];	
	COSubtree *t3 = [COSubtree subtree];
	
	UKNotNil([t1 UUID]);
	UKNil([t1 parent]);
	UKObjectsSame(t1, [t1 root]);
	UKTrue([t1 containsSubtree: t1]);
	
	[t1 addTree: t2];
	
	UKObjectsSame(t1, [t2 parent]);	
	UKObjectsSame(t1, [t2 root]);
	UKNil([t1 parent]);	
	UKObjectsSame(t1, [t1 root]);
	
	UKTrue([t1 containsSubtree: t2]);
	UKObjectsEqual(S([t1 UUID], [t2 UUID]), [t1 allUUIDs]);
	UKObjectsEqual(S([t2 UUID]), [t1 allDescendentSubtreeUUIDs]);
	UKObjectsEqual(S([t2 UUID]), [t1 directDescendentSubtreeUUIDs]);
	UKObjectsEqual(A(t2), [t1 directDescendentSubtrees]);
	UKIntsEqual(2, [[t1 allContainedStoreItems] count]);
	UKIntsEqual(1, [[t2 allUUIDs] count]);		
	UKTrue(t2 == [t1 subtreeWithUUID: [t2 UUID]]);
	UKObjectsEqual([COItemPath pathWithItemUUID: [t1 UUID]
					 unorderedCollectionName: @"contents"
										type: [COType setWithPrimitiveType: [COType embeddedItemType]]], 
				[t1 itemPathOfSubtreeWithUUID: [t2 UUID]]);
	
	[t2 addTree: t3];
	
	UKTrue([t1 containsSubtree: t3]);
	UKObjectsEqual(S([t1 UUID], [t2 UUID], [t3 UUID]), [t1 allUUIDs]);
	UKObjectsEqual(S([t2 UUID], [t3 UUID]), [t1 allDescendentSubtreeUUIDs]);
	UKObjectsEqual(S([t2 UUID]), [t1 directDescendentSubtreeUUIDs]);
	UKObjectsEqual(A(t2), [t1 directDescendentSubtrees]);
	UKIntsEqual(3, [[t1 allContainedStoreItems] count]);
	UKIntsEqual(2, [[t2 allUUIDs] count]);		
	UKObjectsSame(t3, [t1 subtreeWithUUID: [t3 UUID]]);
	UKObjectsEqual([COItemPath pathWithItemUUID: [t2 UUID]
					 unorderedCollectionName: @"contents"
										type: [COType setWithPrimitiveType: [COType embeddedItemType]]], 
				[t1 itemPathOfSubtreeWithUUID: [t3 UUID]]);
}

- (void) testSubtreeEquality
{
	COSubtree *t1 = [COSubtree subtree];
	COSubtree *t2 = [COSubtree subtree];	
	COSubtree *t3 = [COSubtree subtree];
	[t1 addTree: t2];
	[t2 addTree: t3];

	COSubtree *t1a = [[t1 copy] autorelease];
	UKObjectsEqual(t1, t1a);

	COSubtree *t2a = [[t1a contents] anyObject];
	UKObjectsEqual(t2, t2a);

	COSubtree *t3b = [COSubtree subtree];
	[t2a addTree: t3b];

	UKObjectsNotEqual(t1, t1a);
	UKObjectsNotEqual(t2, t2a);

	[t2a removeSubtreeWithUUID: [t3b UUID]];

	UKObjectsEqual(t1, t1a);
	UKObjectsEqual(t2, t2a);	

	UKTrue(t1a == [t2a parent]);		
}

- (void) testSubtreeCreationFromItems
{
	COSubtree *t1 = [COSubtree subtree];
	COSubtree *t2 = [COSubtree subtree];	
	COSubtree *t3 = [COSubtree subtree];
	[t1 addTree: t2];
	[t2 addTree: t3];

	COSubtree *t1a = [COSubtree subtreeWithItemSet: [t1 allContainedStoreItems]
										  rootUUID: [t1 UUID]];
	UKObjectsEqual(t1, t1a);
	
	COSubtree *t2a = [COSubtree subtreeWithItemSet: [t2 allContainedStoreItems]
										  rootUUID: [t2 UUID]];
	UKObjectsEqual(t2, t2a);
}

- (void) testSubtreePlistRoundTrip
{
	COSubtree *t1 = [COSubtree subtree];
	COSubtree *t2 = [COSubtree subtree];	
	COSubtree *t3 = [COSubtree subtree];
	[t1 addTree: t2];
	[t2 addTree: t3];
	
	COSubtree *t1a = [COSubtree subtreeWithPlist: [t1 plist]];
	UKObjectsEqual(t1, t1a);
	
	COSubtree *t2a = [COSubtree subtreeWithPlist: [t2 plist]];
	UKObjectsEqual(t2, t2a);
}


// From ObjectMerging - TestRelationshipIntegrity

- (void)testBasicRelationshipIntegrity
{
	// Test one-to-many relationships
	
	COSubtree *o1 = [COSubtree subtree];
	COSubtree *o2 = [COSubtree subtree];
	COSubtree *o3 = [COSubtree subtree];
	
	[o1 addTree: o2];
	[o2 addTree: o3];
	
	UKNil([o1 parent]);
	UKObjectsEqual(S(o2), [o1 contents]);
	UKObjectsSame(o1, [o2 parent]);
	UKObjectsEqual(S(o3), [o2 contents]);
	UKObjectsSame(o2, [o3 parent]);
	UKObjectsEqual([NSSet set], [o3 contents]);

	
	// FIXME: Not supported yet.
	
	// Test many-to-many relationships
	
//	COObject *t1 = [ctx insertObjectWithEntityName: @"Anonymous.COCollection"]; // See COObject.m for metamodel definition
//	COObject *t2 = [ctx insertObjectWithEntityName: @"Anonymous.COCollection"];
//	COObject *t3 = [ctx insertObjectWithEntityName: @"Anonymous.COCollection"];
//	
//	[t1 addObject: o1 forProperty: @"contents"];
//	[t2 addObject: o1 forProperty: @"contents"];
//	
//	UKObjectsEqual(S(t1, t2), [o1 valueForProperty: @"parentCollections"]);
//	
//	[o2 addObject: t2 forProperty: @"parentCollections"];
//	[o2 addObject: t3 forProperty: @"parentCollections"];
//	
//	UKObjectsEqual(S(o1), [t1 valueForProperty: @"contents"]);
//	UKObjectsEqual(S(o1, o2), [t2 valueForProperty: @"contents"]);
//	UKObjectsEqual(S(o2), [t3 valueForProperty: @"contents"]);
//	
//	[ctx release];
//	[store release];
//	DELETE_STORE;
}

- (void)testRelationshipIntegrityForMove
{
	COSubtree *o1 = [COSubtree subtree];
	COSubtree *o2 = [COSubtree subtree];
	COSubtree *o3 = [COSubtree subtree];
	
	[o1 addTree: o2];

	UKObjectsEqual(S(o2), [o1 contents]);
	UKObjectsEqual([NSSet set], [o3 contents]);
	
	[o3 addTree: o2]; // should add o2 to o3's contents, and remove o2 from o1
	
	UKObjectsEqual([NSSet set], [o1 contents]);
	UKObjectsEqual(S(o2), [o3 contents]);
	
	// Check that removing an object from a group nullifys that object's parent group pointer
	
	[o3 removeSubtree: o2];
	UKNil([o2 parent]);
}

//- (void)testRelationshipIntegrityMarksDamage
//{
//	COStore *store = [[COStore alloc] initWithURL: STORE_URL];
//	COEditingContext *ctx = [[COEditingContext alloc] initWithStore: store];
//	
//	COObject *o1 = [ctx insertObjectWithEntityName: @"Anonymous.COContainer"]; // See COObject.m for metamodel definition
//	COObject *o2 = [ctx insertObjectWithEntityName: @"Anonymous.COContainer"];
//	COObject *o3 = [ctx insertObjectWithEntityName: @"Anonymous.COContainer"];
//	[ctx commit];
//	
//	UKFalse([ctx objectHasChanges: [o1 UUID]]);
//	UKFalse([ctx objectHasChanges: [o2 UUID]]);
//	UKFalse([ctx objectHasChanges: [o3 UUID]]);
//	
//	[o2 setValue: o1 forProperty: @"parentContainer"]; // should add o2 to o1's contents
//	UKTrue([ctx objectHasChanges: [o1 UUID]]);
//	UKTrue([ctx objectHasChanges: [o2 UUID]]);
//	UKFalse([ctx objectHasChanges: [o3 UUID]]);
//	
//	[ctx commit];
//	UKFalse([ctx objectHasChanges: [o1 UUID]]);
//	UKFalse([ctx objectHasChanges: [o2 UUID]]);
//	UKFalse([ctx objectHasChanges: [o3 UUID]]);
//	
//	[o2 setValue: o3 forProperty: @"parentContainer"]; // should add o2 to o3's contents, and remove o2 from o1
//	UKTrue([ctx objectHasChanges: [o1 UUID]]);
//	UKTrue([ctx objectHasChanges: [o2 UUID]]);
//	UKTrue([ctx objectHasChanges: [o3 UUID]]);
//	
//	[ctx commit];
//	
//	[o3 removeObject: o2 forProperty: @"contents"]; // should make o2's parentContainer nil
//	UKFalse([ctx objectHasChanges: [o1 UUID]]);
//	UKTrue([ctx objectHasChanges: [o2 UUID]]);
//	UKTrue([ctx objectHasChanges: [o3 UUID]]);	
//	
//	[ctx release];
//	[store release];
//	DELETE_STORE;
//}

- (void)testShoppingList
{
	COSubtree *workspace = [COSubtree subtree];
	COSubtree *document1 = [COSubtree subtree];
	COSubtree *group1 = [COSubtree subtree];
	COSubtree *leaf1 = [COSubtree subtree];
	COSubtree *leaf2 = [COSubtree subtree];
	COSubtree *group2 = [COSubtree subtree];
	COSubtree *leaf3 = [COSubtree subtree];
	
	COSubtree *document2 = [COSubtree subtree];
	
	[workspace addTree: document1];
	[workspace addTree: document2];
	[document1 addTree: group1];
	[group1 addTree: leaf1];
	[group1 addTree: leaf2];	
	[document1 addTree: group2];	
	[group2 addTree: leaf3];
	
	// Now make some changes
	
	[group2 addTree: leaf2];
	[document2 addTree: group2];
	
	UKObjectsSame(workspace, [document1 parent]);
	UKObjectsSame(workspace, [document2 parent]);	
	UKObjectsSame(document1, [group1 parent]);	
	UKObjectsSame(document2, [group2 parent]);	
	UKObjectsSame(group1, [leaf1 parent]);	
	UKObjectsSame(group2, [leaf2 parent]);	
	UKObjectsSame(group2, [leaf3 parent]);	
	UKObjectsEqual(S(document1, document2), [workspace contents]);
	UKObjectsEqual(S(group1), [document1 contents]);
	UKObjectsEqual(S(group2), [document2 contents]);
	UKObjectsEqual(S(leaf1), [group1 contents]);
	UKObjectsEqual(S(leaf2, leaf3), [group2 contents]);
}

@end
