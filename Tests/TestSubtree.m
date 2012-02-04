#import "TestCommon.h"
#import "COType.h"
#import "COItemPath.h"

void testSubtreeBasic(void);
void testSubtreeEquality(void);

void testSubtreeBasic()
{
	COSubtree *t1 = [COSubtree subtree];
	COSubtree *t2 = [COSubtree subtree];	
	COSubtree *t3 = [COSubtree subtree];
	
	EWTestTrue(nil != [t1 UUID]);
	EWTestTrue(nil == [t1 parent]);
	EWTestTrue(t1 == [t1 root]);
	EWTestTrue(![t1 containsSubtreeWithUUID: [t1 UUID]]);
	
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

void testSubtreeEquality()
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

void testSubtree()
{
	testSubtreeBasic();
	testSubtreeEquality();
}