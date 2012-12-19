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
	UKNotNil(childCopy);
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


#if 0

- (void)testInsertObject
{
	COEditingContext *ctx = NewContext();
	UKFalse([ctx hasChanges]);
	
	
	COObject *obj = [ctx insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	UKNotNil(obj);
	UKTrue([obj isKindOfClass: [COObject class]]);
	
	NSArray *expectedProperties = [NSArray arrayWithObjects: @"parentContainer", @"parentCollections", @"contents", @"label", nil];
	UKObjectsEqual([NSSet setWithArray: expectedProperties],
				   [NSSet setWithArray: [obj persistentPropertyNames]]);

	UKObjectsSame(obj, [ctx objectWithUUID: [obj UUID]]);
	
	UKTrue([ctx hasChanges]);
	
	UKNotNil([obj valueForProperty: @"parentCollections"]);
	UKNotNil([obj valueForProperty: @"contents"]);
	
	TearDownContext(ctx);
}

- (void)testBasicPersistence
{
	COUUID *objUUID;
	
	{
		COStore *store = [[COStore alloc] initWithURL: STORE_URL];
		COEditingContext *ctx = [[COEditingContext alloc] initWithStore: store];
		COObject *obj = [ctx insertObjectWithEntityName: @"Anonymous.OutlineItem"];
		objUUID = [[obj UUID] retain];
		[obj setValue: @"Hello" forProperty: @"label"];
		[ctx commit];
		[ctx release];
		[store release];
	}
	
	{
		COStore *store = [[COStore alloc] initWithURL: STORE_URL];
		COEditingContext *ctx = [[COEditingContext alloc] initWithStore: store];
		COObject *obj = [ctx objectWithUUID: objUUID];
		UKNotNil(obj);
		NSArray *expectedProperties = [NSArray arrayWithObjects: @"parentContainer", @"parentCollections", @"contents", @"label", nil];
		UKObjectsEqual([NSSet setWithArray: expectedProperties],
					   [NSSet setWithArray: [obj persistentPropertyNames]]);
		UKStringsEqual(@"Hello", [obj valueForProperty: @"label"]);
		[ctx release];
		[store release];
	}
	[objUUID release];
	DELETE_STORE;
}


- (void)testDiscardChanges
{
	COEditingContext *ctx = NewContext();

	UKFalse([ctx hasChanges]);
		
	COObject *o1 = [ctx insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	COUUID *u1 = [[o1 UUID] retain];
	
	// FIXME: It's not entirely clear what this should do
	[ctx discardAllChanges];
	UKNil([ctx objectWithUUID: u1]);
	
	UKFalse([ctx hasChanges]);
	COObject *o2 = [ctx insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	[o2 setValue: @"hello" forProperty: @"label"];
	[ctx commit];
	UKObjectsEqual(@"hello", [o2 valueForProperty: @"label"]);
	
	[o2 setValue: @"bye" forProperty: @"label"];
	[ctx discardAllChanges];
	UKObjectsEqual(@"hello", [o2 valueForProperty: @"label"]);
	
	TearDownContext(ctx);
}

- (void)testCopyingBetweenContextsWithNoStoreSimple
{
	COEditingContext *ctx1 = [[COEditingContext alloc] init];
	COEditingContext *ctx2 = [[COEditingContext alloc] init];

	COObject *o1 = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	[o1 setValue: @"Shopping" forProperty: @"label"];
	
	COObject *o1copy = [ctx2 insertObject: o1];
	UKNotNil(o1copy);
	UKObjectsSame(ctx1, [o1 editingContext]);
	UKObjectsSame(ctx2, [o1copy editingContext]);
	UKStringsEqual(@"Shopping", [o1copy valueForProperty: @"label"]);

	[ctx1 release];
	[ctx2 release];
}

- (void)testCopyingBetweenContextsWithNoStoreAdvanced
{
	COEditingContext *ctx1 = [[COEditingContext alloc] init];
	COEditingContext *ctx2 = [[COEditingContext alloc] init];
	
	COContainer *parent = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	COContainer *child = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	COContainer *subchild = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];

	[parent setValue: @"Shopping" forProperty: @"label"];
	[child setValue: @"Groceries" forProperty: @"label"];
	[subchild setValue: @"Pizza" forProperty: @"label"];
	[child addObject: subchild];
	[parent addObject: child];

	// We are going to copy 'child' from ctx1 to ctx2. It should copy both
	// 'child' and 'subchild', but not 'parent'
	
	COContainer *childCopy = [ctx2 insertObject: child];
	UKNotNil(childCopy);
	UKObjectsSame(ctx2, [childCopy editingContext]);
	UKNil([childCopy valueForProperty: @"parentContainer"]);
	UKStringsEqual(@"Groceries", [childCopy valueForProperty: @"label"]);
	UKNotNil([childCopy contentArray]);
	
	COContainer *subchildCopy = [[childCopy contentArray] firstObject];
	UKNotNil(subchildCopy);
	UKObjectsSame(ctx2, [subchildCopy editingContext]);
	UKStringsEqual(@"Pizza", [subchildCopy valueForProperty: @"label"]);
				   
	[ctx1 release];
	[ctx2 release];
}

- (void)testCopyingBetweenContextsWithSharedStore
{
	COEditingContext *ctx1 = NewContext();
	COEditingContext *ctx2 = [[COEditingContext alloc] initWithStore: [ctx1 store]];
	
	COContainer *parent = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	COContainer *child = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	COContainer *subchild = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	
	[parent setValue: @"Shopping" forProperty: @"label"];
	[child setValue: @"Groceries" forProperty: @"label"];
	[subchild setValue: @"Pizza" forProperty: @"label"];
	[child addObject: subchild];
	[parent addObject: child];
	
	[ctx1 commit];
	
	// We won't commit this
	[parent setValue: @"Todo" forProperty: @"label"];
	
	// We'll add another sub-child and leave it uncommitted.
	COContainer *subchild2 = [ctx1 insertObjectWithEntityName: @"Anonymous.OutlineItem"];
	[subchild2 setValue: @"Salad" forProperty: @"label"];
	[child addObject: subchild2];
	
	// We are going to copy 'child' from ctx1 to ctx2. It should copy
	// 'child', 'subchild', and 'subchild2', but not 'parent' (so 
	// renaming parent from "Shopping" to "Todo" should not be propagated.)
	
	COContainer *childCopy = [ctx2 insertObject: child];
	UKNotNil(childCopy);
	UKObjectsSame(ctx2, [childCopy editingContext]);
	UKObjectsEqual([parent UUID], [[childCopy valueForProperty: @"parentContainer"] UUID]);
	UKStringsEqual(@"Shopping", [[childCopy valueForProperty: @"parentContainer"] valueForProperty: @"label"]);
	UKStringsEqual(@"Groceries", [childCopy valueForProperty: @"label"]);
	UKNotNil([childCopy contentArray]);
	UKIntsEqual(2, [[childCopy contentArray] count]);
	if (2 == [[childCopy contentArray] count])
	{
		COContainer *subchildCopy = [[childCopy contentArray] firstObject];
		UKNotNil(subchildCopy);
		UKObjectsSame(ctx2, [subchildCopy editingContext]);
		UKStringsEqual(@"Pizza", [subchildCopy valueForProperty: @"label"]);
		
		COContainer *subchild2Copy = [[childCopy contentArray] objectAtIndex: 1];
		UKNotNil(subchild2Copy);
		UKObjectsSame(ctx2, [subchild2Copy editingContext]);
		UKStringsEqual(@"Salad", [subchild2Copy valueForProperty: @"label"]);
	}
	[ctx2 release];
	TearDownContext(ctx1);
}


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

#endif

@end
