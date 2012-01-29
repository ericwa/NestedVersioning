#import "COSubtreeCopy.h"
#import "COMacros.h"

@implementation COSubtreeCopy 

- (COSubtree *) subtree
{
	return subtree;
}

- (ETUUID *) replacementUUIDForUUID: (ETUUID*)aUUID
{
	return [mappingDictionary objectForKey: aUUID];
}

- (void) dealoc
{
	[subtree release];
	[mappingDictionary release];
	[super dealloc];
}

@end


@implementation COSubtreeCopy (Private)

+ (COSubtreeCopy *) subtreeCopyWithSubtree: (COSubtree*)aSubtree
						 mappingDictionary: (NSDictionary *)aDict
{
	COSubtreeCopy *aSubtreeCopy = [[[COSubtreeCopy alloc] init] autorelease];
	ASSIGN(aSubtreeCopy->subtree, aSubtree);
	ASSIGN(aSubtreeCopy->mappingDictionary, aDict);
	return aSubtreeCopy;
}

@end
