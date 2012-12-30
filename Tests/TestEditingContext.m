#import "TestCommon.h"

@interface TestEditingContext : NSObject <UKTest> {
	
}

@end


@implementation TestEditingContext

- (void)testCreate
{
	COEditingContext *ctx = [[COEditingContext alloc] init];
	UKNotNil(ctx);
    
    COObject *root = [ctx rootObject];
    UKNotNil(root);
    
}

- (COObject *) itemWithLabel: (NSString *)label
{
	COEditingContext *ctx = [[[COEditingContext alloc] init] autorelease];
    [[ctx rootObject] setValue: label
                  forAttribute: @"label"
                          type: [COType stringType]];
    return [ctx rootObject];    
}

- (void)testCopyingBetweenContextsWithNoStoreAdvanced
{
	COEditingContext *ctx1 = [[COEditingContext alloc] init];
	COEditingContext *ctx2 = [[COEditingContext alloc] init];
	
	COObject *parent = [[ctx1 rootObject] addTree: [self itemWithLabel: @"Shopping"]];
	COObject *child = [parent addTree: [self itemWithLabel: @"Groceries"]];
	COObject *subchild = [child addTree: [self itemWithLabel: @"Pizza"]];
    
    UKObjectsEqual(S([[ctx1 rootObject] UUID], [parent UUID], [child UUID], [subchild UUID]),
                   [ctx1 allUUIDs]);
    
	// We are going to copy 'child' from ctx1 to ctx2. It should copy both
	// 'child' and 'subchild', but not 'parent'
	                                                  
	COObject *childCopy = [[ctx2 rootObject] addTree: child];
	UKObjectsEqual(childCopy, child);
	UKObjectsSame(ctx2, [childCopy editingContext]);
	UKObjectsSame([ctx2 rootObject], [childCopy parent]);
	UKStringsEqual(@"Groceries", [childCopy valueForAttribute: @"label"]);
	UKNotNil([childCopy contents]);
    
	COObject *subchildCopy = [[childCopy contents] anyObject];
	UKNotNil(subchildCopy);
	UKObjectsSame(ctx2, [subchildCopy editingContext]);
	UKStringsEqual(@"Pizza", [subchildCopy valueForAttribute: @"label"]);
    
	[ctx1 release];
	[ctx2 release];
}

- (void)testCopyingBetweenContextsCornerCases
{
	COEditingContext *ctx1 = [[COEditingContext alloc] init];
	COEditingContext *ctx2 = [[COEditingContext alloc] init];
	
    COObject *o1 = [[ctx1 rootObject] addTree: [self itemWithLabel: @"Shopping"]];
    COObject *o2 = [o1 addTree: [self itemWithLabel: @"Gift"]];
    UKNotNil(o1);
    
	COObject *o1copy = [[ctx2 rootObject] addTree: o1];
	COObject *o1copy2 = [[ctx2 rootObject] addTree: o1]; // copy o1 into ctx2 a second time
    
    COObject *o2copy = [[o1copy directDescendentSubtrees] anyObject];
	COObject *o2copy2 = [[o1copy2 directDescendentSubtrees] anyObject];
    UKObjectsNotSame(o1copy, o1copy2);
    
    UKObjectsEqual([o1 UUID], [o1copy UUID]);
    UKObjectsEqual([o2 UUID], [o2copy UUID]);
    UKObjectsNotEqual([o1 UUID], [o1copy2 UUID]);
    UKObjectsNotEqual([o2 UUID], [o2copy2 UUID]);
	
	[ctx1 release];
	[ctx2 release];
}

- (void)testMovingWithinContext
{
	COEditingContext *ctx1 = [[COEditingContext alloc] init];
	
    COObject *list1 = [[ctx1 rootObject] addTree: [self itemWithLabel: @"List1"]];
    COObject *list2 = [[ctx1 rootObject] addTree: [self itemWithLabel: @"List2"]];
    COObject *itemA = [list1 addTree: [self itemWithLabel: @"ItemA"]];
    COObject *itemB = [list2 addTree: [self itemWithLabel: @"ItemB"]];
    
    UKObjectsEqual([list1 directDescendentSubtrees], S(itemA));
    UKObjectsEqual([list2 directDescendentSubtrees], S(itemB));
    UKObjectsSame(list1, [itemA parent]);
    UKObjectsSame(list2, [itemB parent]);
    
    // move itemA to list2
    
    [list2 addTree: itemA];
    
    UKObjectsSame(list2, [itemA parent]);
    UKObjectsEqual([list1 directDescendentSubtrees], [NSSet set]);
    UKObjectsEqual([list2 directDescendentSubtrees], S(itemA, itemB));
    
	[ctx1 release];
}

- (void)testObjectEquality
{
	COEditingContext *ctx1 = [[COEditingContext alloc] init];
	
    COObject *list1 = [[ctx1 rootObject] addTree: [self itemWithLabel: @"List1"]];
    COObject *itemA = [list1 addTree: [self itemWithLabel: @"ItemA"]];
    COObject *itemA1 = [itemA addTree: [self itemWithLabel: @"ItemA1"]];
    
    COEditingContext *ctx2 = [ctx1 copy];
    
    UKObjectsEqual(ctx1, ctx2);
    UKObjectsEqual([ctx1 rootObject], [ctx2 rootObject]);

    // now make an edit in ctx2
    
    [[ctx2 objectForUUID: [itemA UUID]] setValue: @"modified" forAttribute: @"test" type: [COType stringType]];
    
    UKObjectsNotEqual(ctx1, ctx2);
    UKObjectsNotEqual([ctx1 rootObject], [ctx2 rootObject]);
    UKObjectsNotEqual(list1, [ctx2 objectForUUID: [list1 UUID]]);
    UKObjectsNotEqual(itemA, [ctx2 objectForUUID: [itemA UUID]]);
    UKObjectsEqual(itemA1, [ctx2 objectForUUID: [itemA1 UUID]]);
    
    // undo the change
    
    [[ctx2 objectForUUID: [itemA UUID]] removeValueForAttribute: @"test"];
    
    UKObjectsEqual(ctx1, ctx2);
    UKObjectsEqual([ctx1 rootObject], [ctx2 rootObject]);
}

- (void)testChangeTrackingBasic
{
	COEditingContext *ctx1 = [[COEditingContext alloc] init];
	
    UKObjectsEqual([NSSet set], [ctx1 insertedObjectUUIDs]);
    UKObjectsEqual([NSSet set], [ctx1 deletedObjectUUIDs]);
    UKObjectsEqual([NSSet set], [ctx1 modifiedObjectUUIDs]);
    
    COObject *list1 = [[ctx1 rootObject] addTree: [self itemWithLabel: @"List1"]];

    UKObjectsEqual(S([list1 UUID]), [ctx1 insertedObjectUUIDs]);
    UKObjectsEqual([NSSet set], [ctx1 deletedObjectUUIDs]);
    UKObjectsEqual(S([[ctx1 rootObject] UUID]), [ctx1 modifiedObjectUUIDs]);
    
    [ctx1 clearChangeTracking];
    
    UKObjectsEqual([NSSet set], [ctx1 insertedObjectUUIDs]);
    UKObjectsEqual([NSSet set], [ctx1 deletedObjectUUIDs]);
    UKObjectsEqual([NSSet set], [ctx1 modifiedObjectUUIDs]);
}

- (void)testShoppingList
{
	COEditingContext *ctx1 = [[COEditingContext alloc] init];    
    
	COObject *workspace = [[ctx1 rootObject] addTree: [self itemWithLabel: @"Workspace"]];
	COObject *document1 = [workspace addTree: [self itemWithLabel: @"Document1"]];
	COObject *group1 = [document1 addTree: [self itemWithLabel: @"Group1"]];
	COObject *leaf1 = [group1 addTree: [self itemWithLabel: @"Leaf1"]];
	COObject *leaf2 = [group1 addTree: [self itemWithLabel: @"Leaf2"]];
	COObject *group2 = [document1 addTree: [self itemWithLabel: @"Group2"]];
	COObject *leaf3 = [group2 addTree: [self itemWithLabel: @"Leaf3"]];
	
	COObject *document2 = [workspace addTree: [self itemWithLabel: @"Document2"]];
		
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

- (void) testSubtreeCreationFromItemsWithCycle
{
	COMutableItem *parent = [COMutableItem item];
	COMutableItem *child = [COMutableItem item];
	[parent setValue: [child UUID] forAttribute: @"cycle" type: [COType embeddedItemType]];
	[child setValue: [parent UUID] forAttribute: @"cycle" type: [COType embeddedItemType]];
    
    COItemTree *objectTree = [COItemTree treeWithItems: A(parent, child) rootItemUUID: [parent UUID]];
    
    UKRaisesException([COEditingContext editingContextWithObjectTree: objectTree]);
}


- (void) testSubtreeBasic
{
	COEditingContext *ctx1 = [[COEditingContext alloc] init];
    COObject *t1 = [ctx1 rootObject];
	
	UKNotNil([t1 UUID]);
	UKNil([t1 parent]);
	UKObjectsSame(t1, [t1 root]);
	UKTrue([t1 containsObject: t1]);
	
    COObject *t2 = [t1 addTree: [self itemWithLabel: @"t2"]];
	
	UKObjectsSame(t1, [t2 parent]);
	UKObjectsSame(t1, [t2 root]);
	UKNil([t1 parent]);
	UKObjectsSame(t1, [t1 root]);
	
	UKTrue([t1 containsObject: t2]);
	UKObjectsEqual(S([t1 UUID], [t2 UUID]), [t1 allUUIDs]);
	UKObjectsEqual(S([t2 UUID]), [t1 allDescendentSubtreeUUIDs]);
	UKObjectsEqual(S([t2 UUID]), [t1 directDescendentSubtreeUUIDs]);
	UKObjectsEqual(S(t2), [t1 directDescendentSubtrees]);
	UKIntsEqual(2, [[t1 allContainedStoreItems] count]);
	UKIntsEqual(1, [[t2 allUUIDs] count]);
	UKTrue(t2 == [t1 subtreeWithUUID: [t2 UUID]]);
	UKObjectsEqual([COItemPath pathWithItemUUID: [t1 UUID]
                        unorderedCollectionName: @"contents"
                                           type: [COType setWithPrimitiveType: [COType embeddedItemType]]],
                   [t1 itemPathOfSubtreeWithUUID: [t2 UUID]]);
	
    COObject *t3 = [t2 addTree: [self itemWithLabel: @"t3"]];
	
	UKTrue([t1 containsObject: t3]);
	UKObjectsEqual(S([t1 UUID], [t2 UUID], [t3 UUID]), [t1 allUUIDs]);
	UKObjectsEqual(S([t2 UUID], [t3 UUID]), [t1 allDescendentSubtreeUUIDs]);
	UKObjectsEqual(S([t2 UUID]), [t1 directDescendentSubtreeUUIDs]);
	UKObjectsEqual(S(t2), [t1 directDescendentSubtrees]);
	UKIntsEqual(3, [[t1 allContainedStoreItems] count]);
	UKIntsEqual(2, [[t2 allUUIDs] count]);
	UKObjectsSame(t3, [t1 subtreeWithUUID: [t3 UUID]]);
	UKObjectsEqual([COItemPath pathWithItemUUID: [t2 UUID]
                        unorderedCollectionName: @"contents"
                                           type: [COType setWithPrimitiveType: [COType embeddedItemType]]],
                   [t1 itemPathOfSubtreeWithUUID: [t3 UUID]]);
}

- (void) testSubtreeCreationFromItems
{
	COEditingContext *ctx1 = [[COEditingContext alloc] init];
    COObject *t1 = [ctx1 rootObject];
    COObject *t2 = [t1 addTree: [self itemWithLabel: @"t2"]];
    [t2 addTree: [self itemWithLabel: @"t3"]];

    COEditingContext *t1copyCtx = [COEditingContext editingContextWithObjectTree: [COItemTree treeWithItems: [[t1 allContainedStoreItems] allObjects]
                                                                                                     rootItemUUID: [t1 UUID]]];
    

    COEditingContext *t2copyCtx = [COEditingContext editingContextWithObjectTree: [COItemTree treeWithItems: [[t2 allContainedStoreItems] allObjects]
                                                                                                     rootItemUUID: [t2 UUID]]];
    
	UKObjectsEqual(t1, [t1copyCtx rootObject]);
    UKObjectsEqual(t2, [t2copyCtx rootObject]);
}


#if 0

- (void)testCopyingBetweenContextsWithManyToMany
{
	COEditingContext *ctx1 = [[COEditingContext alloc] init];
	COEditingContext *ctx2 = [[COEditingContext alloc] init];

	COCollection *tag1 = [ctx1 insertObjectWithEntityName: @"Anonymous.Tag"];
	COContainer *child = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];

	[tag1 addObject: child];

	// Copy the tag collection to ctx2. At first it will be empty since child isn't in ctx2 yet
	
	COCollection *tag1copy = [ctx2 insertObject: tag1];
	UKObjectsEqual([NSArray array], [tag1copy contentArray]);
	
	COContainer *childcopy = [ctx2 insertObject: child];
	UKObjectsEqual([NSArray arrayWithObject: childcopy], [tag1copy contentArray]);
	
	[ctx1 release];
	[ctx2 release];
}


- (void) testSubtreeCreationFromItemsWithEmbeddedItemUsedTwice
{
	COMutableItem *parent = [COMutableItem item];
	COMutableItem *child1 = [COMutableItem item];
	COMutableItem *child2 = [COMutableItem item];
	COMutableItem *shared = [COMutableItem item];
	
	[parent setValue: S([child1 UUID], [child2 UUID]) forAttribute: @"contents" type: [COType setWithPrimitiveType: [COType embeddedItemType]]];
	[child1 setValue: [shared UUID] forAttribute: @"shared" type: [COType embeddedItemType]];
	[child2 setValue: [shared UUID] forAttribute: @"shared" type: [COType embeddedItemType]];
	
	// illegal, because "shared" is embedded in two places
	
	UKRaisesException([COSubtree subtreeWithItemSet: S(parent, child1, child2, shared) rootUUID: [parent UUID]]);
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

#endif

@end
