#import "COStoreItemTree.h"
#import "Common.h"

@implementation COStoreItemTree

- (id)initWithItems: (NSSet*)aSet root: (ETUUID*)aRoot
{
	NILARG_EXCEPTION_TEST(aSet);
	NILARG_EXCEPTION_TEST(aRoot);
	
	assert([aSet isKindOfClass: [NSSet class]]);
	for (COStoreItem *item in aSet) { assert ([item isKindOfClass: [COStoreItem class]]); }
	assert([aRoot isKindOfClass: [ETUUID class]]);
	
	SUPERINIT
	ASSIGN(items,aSet);
	ASSIGN(root,aRoot);
	return self;
}

- (void) dealloc
{
	[items release];
	[root release];
	[super dealloc];
}

+ (COStoreItemTree *)itemTreeWithItems: (NSSet*)items root: (ETUUID*)aRoot
{
	return [[[self alloc] initWithItems: items root: aRoot] autorelease];
}

- (NSSet *)items
{
	return items;
}
- (ETUUID *)root
{
	return root;
}

- (id)copyWithZone:(NSZone *)zone
{
	NSArray *copiedItems = [[[NSArray alloc] initWithArray: [items allObjects]
												 copyItems: YES] autorelease];
	
	return [COStoreItemTree itemTreeWithItems: [NSSet setWithArray: copiedItems]
										 root: root];
}

/* convenience */

- (COStoreItem *)rootItem
{
	for (COStoreItem *item in items)
	{
		if ([[item UUID] isEqual: root])
		{
			return item;
		}
	}
	[NSException raise: NSInternalInconsistencyException format: @"COStoreItemTree lacks root"];
	return nil;
}

+ (COStoreItemTree *)itemTreeWithItem: (COStoreItem*)anItem
{
	return [COStoreItemTree itemTreeWithItems: [NSSet setWithObject: anItem] root: [anItem UUID]];
}

- (NSSet *)itemUUIDs
{
	NSMutableSet *result = [NSMutableSet set];
	for (COStoreItem *item in items)
	{
		[result addObject: [item UUID]];
	}
	return [NSSet setWithSet: result];
}

@end
