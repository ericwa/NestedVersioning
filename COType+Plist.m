#import "COType+Plist.h"
#import "COTypePrivate.h"
#import "ETUUID.h"
#import "COPath.h"

@interface COInt64Type (Plist)
@end
@interface CODoubleType (Plist)
@end
@interface COStringType (Plist)
@end
@interface COFullTextIndexableStringType (Plist)
@end
@interface COBlobType (Plist)
@end
@interface COCommitType (Plist)
@end
@interface COPathType (Plist)
@end
@interface COEmbeddedItemType (Plist)
@end
@interface COMultivaluedType (Plist)
@end


@implementation COInt64Type (Plist)

- (id) plistValueForValue: (id)aValue
{
	return aValue;
}

- (id) valueForPlistValue: (id)aPlist
{
	return aPlist;
}

@end


@implementation CODoubleType (Plist)

- (id) plistValueForValue: (id)aValue
{
	return aValue;
}

- (id) valueForPlistValue: (id)aPlist
{
	return aPlist;
}

@end


@implementation COStringType (Plist)

- (id) plistValueForValue: (id)aValue
{
	return aValue;
}

- (id) valueForPlistValue: (id)aPlist
{
	return aPlist;
}

@end


@implementation COFullTextIndexableStringType (Plist)

- (id) plistValueForValue: (id)aValue
{
	return aValue;
}

- (id) valueForPlistValue: (id)aPlist
{
	return aPlist;
}

@end


@implementation COBlobType (Plist)

- (id) plistValueForValue: (id)aValue
{
	return aValue;
}

- (id) valueForPlistValue: (id)aPlist
{
	return aPlist;
}

@end


@implementation COCommitType (Plist)

- (id) plistValueForValue: (id)aValue
{
	return [(ETUUID *)aValue stringValue];
}

- (id) valueForPlistValue: (id)aPlist
{
	return [ETUUID UUIDWithString: aPlist];
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


@implementation COEmbeddedItemType (Plist)

- (id) plistValueForValue: (id)aValue
{
	return [(ETUUID *)aValue stringValue];
}

- (id) valueForPlistValue: (id)aPlist
{
	return [ETUUID UUIDWithString: aPlist];
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
