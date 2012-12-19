#import "COObjectTree.h"
#import "COMacros.h"
#import "COUUID.h"
#import "COItem.h"

@implementation COObjectTree

- (id) initWithItemForUUID: (NSDictionary *) itemForUUID
                      root: (COUUID *)root
{
    NSParameterAssert([itemForUUID isKindOfClass: [NSDictionary class]]);
    NSParameterAssert([root isKindOfClass: [COUUID class]]);
    
    SUPERINIT;
    itemForUUID_ = [[NSDictionary alloc] initWithDictionary: itemForUUID copyItems: YES];
    root_ = [root copy];
    return self;
}

- (void) dealloc
{
    [itemForUUID_ release];
    [root_ release];
    [super dealloc];
}

- (COUUID *) root
{
    return root_;
}

- (COItem *) itemForUUID: (COUUID *)aUUID
{
    return [itemForUUID_ objectForKey: aUUID];
}

- (NSArray *) objectUUIDs
{
    return [itemForUUID_ allKeys];
}

- (COObjectTree *) objectTreeWithNameMapping: (NSDictionary *)aMapping;
{
	NSMutableDictionary *newItems = [NSMutableDictionary dictionary];
	
	for (COUUID *uuid in itemForUUID_)
	{
        COItem *oldItem = [itemForUUID_ objectForKey: uuid];
        COItem *newItem = [[oldItem mutableCopyWithNameMapping: aMapping] autorelease];
        [newItems setObject: newItem forKey: [newItem UUID]];
	}
	
    COUUID *newRoot = [aMapping objectForKey: root_];
    if (newRoot == nil)
    {
        newRoot = root_;
    }
    
	return [[[COObjectTree alloc] initWithItemForUUID: newItems root:newRoot] autorelease];
}

@end
