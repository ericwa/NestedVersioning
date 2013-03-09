#import "COType+Plist.h"
#import "COTypePrivate.h"
#import "COUUID.h"
#import "COPath.h"

@interface COPrimitiveType (Plist)
@end
@interface COUUIDType (Plist)
@end
@interface COPathType (Plist)
@end
@interface COMultivaluedType (Plist)
@end


@implementation COPrimitiveType (Plist)

- (id) plistValueForValue: (id)aValue
{
	return aValue;
}

- (id) valueForPlistValue: (id)aPlist
{
	return aPlist;
}

@end

/**
 * Abstract superclass of COCommitType, COReferenceType, COEmbeddedItemType
 */
@implementation COUUIDType (Plist)

- (id) plistValueForValue: (id)aValue
{
	return [(COUUID *)aValue stringValue];
}

- (id) valueForPlistValue: (id)aPlist
{
	return [COUUID UUIDWithString: aPlist];
}

@end


@implementation COPathType (Plist)

- (id) plistValueForValue: (id)aValue
{
	return [(COPath *)aValue stringValue];
}

- (id) valueForPlistValue: (id)aPlist
{
	return [COPath pathWithString: aPlist];
}

@end


@implementation COMultivaluedType (Plist)

- (id) plistValueForValue: (id)aValue
{
	NSMutableArray *result = [NSMutableArray array];
	for (id obj in aValue)
	{
		[result addObject: [primitiveType plistValueForValue: obj]];
	}
	return result;
}

- (id) valueForPlistValue: (id)aPlist
{
	id collection;
	if (!ordered && unique)
	{
		collection = [NSMutableSet set];		
	}
	else if (!ordered && !unique)
	{
		collection = [NSCountedSet set];
	}
	else
	{
		collection = [NSMutableArray array];
	}
		
	for (id obj in aPlist)
	{
		[collection addObject: [primitiveType valueForPlistValue: obj]];
	}
	return collection;
}

@end
