#import "TestCommon.h"

void testSubtree()
{
	COSubtree *t1 = [COSubtree subtree];
	COSubtree *t2 = [COSubtree subtree];	
	COSubtree *t3 = [COSubtree subtree];
	
	EWTestTrue(nil == [t2 parent]);
	EWTestTrue(t2 == [t2 root]);
	
	[t1 addTree: t2];
	
	EWTestTrue(t1 == [t2 parent]);	
	EWTestTrue(t1 == [t2 root]);
	EWTestTrue(nil == [t1 parent]);	
	EWTestTrue(t1 == [t1 root]);
	
	[t2 addTree: t3];
	
	EWTestTrue(t2 == [t3 parent]);
	
	EWTestIntsEqual(3, [[t1 allContainedStoreItems] count]);
	
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