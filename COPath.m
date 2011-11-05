#import "COPath.h"

@implementation COPath

+ (COPath *) pathWithUUIDs: (NSArray*)uuids
{
	COPath *p = [[COPath alloc] init];
	p->array = [[NSArray alloc] initWithArray: uuids];
	return [p autorelease];
}
- (NSArray *) UUIDs
{
	return array;
}
- (void)dealloc
{
	[array release];
	[super dealloc];
}

@end
