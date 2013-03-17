#import "COItemTree.h"
#import "COMacros.h"
#import "COUUID.h"
#import "COItem.h"

@implementation COItemTree

- (id) initWithItemForUUID: (NSDictionary *) itemForUUID
              rootItemUUID: (COUUID *)root
{
    SUPERINIT;
    itemForUUID_ = [itemForUUID retain];
    rootItemUUID_ = [root copy];
    return self;
}

- (void) dealloc
{
    [itemForUUID_ release];
    [rootItemUUID_ release];
    [super dealloc];
}


- (COUUID *) rootItemUUID
{
    return rootItemUUID_;
}

- (COItem *) itemForUUID: (COUUID *)aUUID
{
    return [itemForUUID_ objectForKey: aUUID];
}

- (NSArray *) itemUUIDs
{
    return [itemForUUID_ allKeys];
}

- (NSString *)description
{
	NSMutableString *result = [NSMutableString string];
    
	[result appendFormat: @"[%@ root: %@\n", NSStringFromClass([self class]), rootItemUUID_];
	for (COItem *item in [itemForUUID_ allValues])
	{
		[result appendFormat: @"%@", item];
	}
	[result appendFormat: @"]"];
	
	return result;
}

@end

