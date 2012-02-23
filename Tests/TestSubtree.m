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
	UKTrue([t1 containsSubtreeWithUUID: [t1 UUID]]);
	
	[t1 addTree: t2];
	
	UKObjectsSame(t1, [t2 parent]);	
	UKObjectsSame(t1, [t2 root]);
	UKNil([t1 parent]);	
	UKObjectsSame(t1, [t1 root]);
	
	UKTrue([t1 containsSubtreeWithUUID: [t2 UUID]]);
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
	
	UKTrue([t1 containsSubtreeWithUUID: [t3 UUID]]);
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
}

- (void) testSubtreeDiff
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
	
	UKObjectsEqual(u1, t1);
	
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
	
	UKObjectsEqual(u1, u1_generated_from_diff);
}

@end
