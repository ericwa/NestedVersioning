#import "TestCommon.h"
#import "COType.h"
#import "COItemPath.h"
#import "COSubtreeDiff.h"

static void testSubtreeBasic(void);
static void testSubtreeEquality(void);
static void testSubtreeCreationFromItems(void);
static void testSubtreeDiff(void);

static void testSubtreeBasic()
{
	COSubtree *t1 = [COSubtree subtree];
	COSubtree *t2 = [COSubtree subtree];	
	COSubtree *t3 = [COSubtree subtree];
	
	EWTestTrue(nil != [t1 UUID]);
	EWTestTrue(nil == [t1 parent]);
	EWTestTrue(t1 == [t1 root]);
	EWTestTrue([t1 containsSubtreeWithUUID: [t1 UUID]]);
	
	[t1 addTree: t2];
	
	EWTestTrue(t1 == [t2 parent]);	
	EWTestTrue(t1 == [t2 root]);
	EWTestTrue(nil == [t1 parent]);	
	EWTestTrue(t1 == [t1 root]);
	
	EWTestTrue([t1 containsSubtreeWithUUID: [t2 UUID]]);
	EWTestEqual(S([t1 UUID], [t2 UUID]), [t1 allUUIDs]);
	EWTestEqual(S([t2 UUID]), [t1 allDescendentSubtreeUUIDs]);
	EWTestEqual(S([t2 UUID]), [t1 directDescendentSubtreeUUIDs]);
	EWTestEqual(A(t2), [t1 directDescendentSubtrees]);
	EWTestIntsEqual(2, [[t1 allContainedStoreItems] count]);
	EWTestIntsEqual(1, [[t2 allUUIDs] count]);		
	EWTestTrue(t2 == [t1 subtreeWithUUID: [t2 UUID]]);
	EWTestEqual([COItemPath pathWithItemUUID: [t1 UUID]
					 unorderedCollectionName: @"contents"
										type: [COType setWithPrimitiveType: [COType embeddedItemType]]], 
				[t1 itemPathOfSubtreeWithUUID: [t2 UUID]]);
	
	[t2 addTree: t3];
	
	EWTestTrue([t1 containsSubtreeWithUUID: [t3 UUID]]);
	EWTestEqual(S([t1 UUID], [t2 UUID], [t3 UUID]), [t1 allUUIDs]);
	EWTestEqual(S([t2 UUID], [t3 UUID]), [t1 allDescendentSubtreeUUIDs]);
	EWTestEqual(S([t2 UUID]), [t1 directDescendentSubtreeUUIDs]);
	EWTestEqual(A(t2), [t1 directDescendentSubtrees]);
	EWTestIntsEqual(3, [[t1 allContainedStoreItems] count]);
	EWTestIntsEqual(2, [[t2 allUUIDs] count]);		
	EWTestTrue(t3 == [t1 subtreeWithUUID: [t3 UUID]]);
	EWTestEqual([COItemPath pathWithItemUUID: [t2 UUID]
					 unorderedCollectionName: @"contents"
										type: [COType setWithPrimitiveType: [COType embeddedItemType]]], 
				[t1 itemPathOfSubtreeWithUUID: [t3 UUID]]);
}

static void testSubtreeEquality()
{
	COSubtree *t1 = [COSubtree subtree];
	COSubtree *t2 = [COSubtree subtree];	
	COSubtree *t3 = [COSubtree subtree];
	[t1 addTree: t2];
	[t2 addTree: t3];

	COSubtree *t1a = [[t1 copy] autorelease];
	EWTestEqual(t1, t1a);

	COSubtree *t2a = [[t1a contents] anyObject];
	EWTestEqual(t2, t2a);

	COSubtree *t3b = [COSubtree subtree];
	[t2a addTree: t3b];

	EWTestTrue(![t1 isEqual: t1a]);
	EWTestTrue(![t2 isEqual: t2a]);

	[t2a removeSubtreeWithUUID: [t3b UUID]];

	EWTestEqual(t1, t1a);
	EWTestEqual(t2, t2a);	

	EWTestTrue(t1a == [t2a parent]);		
}

static void testSubtreeCreationFromItems()
{
	COSubtree *t1 = [COSubtree subtree];
	COSubtree *t2 = [COSubtree subtree];	
	COSubtree *t3 = [COSubtree subtree];
	[t1 addTree: t2];
	[t2 addTree: t3];

	COSubtree *t1a = [COSubtree subtreeWithItemSet: [t1 allContainedStoreItems]
										  rootUUID: [t1 UUID]];
	EWTestEqual(t1, t1a);
}

static void testSubtreeDiff()
{
	COSubtree *t1 = [COSubtree subtree];
	COSubtree *t2 = [COSubtree subtree];	
	COSubtree *t3a = [COSubtree subtree];
	COSubtree *t3b = [COSubtree subtree];
	[t1 addTree: t2];
	[t2 addTree: t3a];
	[t2 addTree: t3b];
	
	
	// Create a copy and modify it.
	COSubtree *u1 = [[t1 copy] autorelease];
	
	EWTestEqual(u1, t1);
	
	COSubtree *u2 = [u1 subtreeWithUUID: [t2 UUID]];
	COSubtree *u3a = [u1 subtreeWithUUID: [t3a UUID]];

	[u2 removeSubtreeWithUUID: [t3b UUID]];
	
	COSubtree *u4 = [COSubtree subtree];
	[u3a addTree: u4];
	
	[u4 setPrimitiveValue: @"This node was added"
			 forAttribute: @"comment"
					 type: [COType stringType]];
	
	
	// Test creating a diff
	COSubtreeDiff *diff_t1_u1 = [COSubtreeDiff diffSubtree: t1 withSubtree: u1];
	
	COSubtree *u1_generated_from_diff = [diff_t1_u1 subtreeWithDiffAppliedToSubtree: t1];
	
	EWTestEqual(u1, u1_generated_from_diff);
}


void testSubtree()
{
	testSubtreeBasic();
	testSubtreeEquality();
	testSubtreeCreationFromItems();
	testSubtreeDiff();
}