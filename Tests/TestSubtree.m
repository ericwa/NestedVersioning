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

@end
