#import "COType+String.h"
#import "COTypePrivate.h"
#import "COUUID.h"
#import "COPath.h"

@interface COInt64Type (String)
@end
@interface CODoubleType (String)
@end
@interface COStringType (String)
@end
@interface COFullTextIndexableStringType (String)
@end
@interface COBlobType (String)
@end
@interface COCommitType (String)
@end
@interface COPathType (String)
@end
@interface COEmbeddedItemType (String)
@end
@interface COMultivaluedType (String)
@end


@implementation COInt64Type (String)

- (BOOL) isValidStringValue: (NSString *)aString
{
	return YES;
}

- (NSString *) stringValueForValue: (id)aValue
{
	return [aValue stringValue];
}

- (id) valueForStringValue: (NSString *)aString
{
	return [NSNumber numberWithLongLong: [aString longLongValue]];
}

- (BOOL) supportsRepresentationAsString
{
	return YES;
}

@end


@implementation CODoubleType (String)

- (BOOL) isValidStringValue: (NSString *)aString
{
	return YES;
}

- (NSString *) stringValueForValue: (id)aValue
{
	return [aValue stringValue];
}

- (id) valueForStringValue: (NSString *)aString
{
	return [NSNumber numberWithDouble: [aString doubleValue]];
}

- (BOOL) supportsRepresentationAsString
{
	return YES;
}

@end


@implementation COStringType (String)

- (BOOL) isValidStringValue: (NSString *)aString
{
	return YES;
}

- (NSString *) stringValueForValue: (id)aValue
{
	return aValue;
}

- (id) valueForStringValue: (NSString *)aString
{
	return aString;
}

- (BOOL) supportsRepresentationAsString
{
	return YES;
}

@end


@implementation COFullTextIndexableStringType (String)

- (BOOL) isValidStringValue: (NSString *)aString
{
	return YES;
}

- (NSString *) stringValueForValue: (id)aValue
{
	return aValue;
}

- (id) valueForStringValue: (NSString *)aString
{
	return aString;
}

- (BOOL) supportsRepresentationAsString
{
	return YES;
}

@end


@implementation COBlobType (String)

- (BOOL) isValidStringValue: (NSString *)aString
{
	return NO;
}

- (BOOL) supportsRepresentationAsString
{
	return NO;
}

@end


@implementation COCommitType (String)

- (BOOL) isValidStringValue: (NSString *)aString
{
	COUUID *aUUID = nil;
	@try
	{
		aUUID = [COUUID UUIDWithString: aString];
	}
	@catch (NSException *exception)
	{
		return NO;
	}
	return aUUID != nil;
}

- (NSString *) stringValueForValue: (id)aValue
{
	return [(COUUID *)aValue stringValue];
}

- (id) valueForStringValue: (NSString *)aString
{
	return [COUUID UUIDWithString: aString];
}

- (BOOL) supportsRepresentationAsString
{
	return YES;
}

@end


@implementation COPathType (String)

- (BOOL) isValidStringValue: (NSString *)aString
{
	COPath *aPath = nil;
	@try
	{
		aPath = [COPath pathWithString: aString];
	}
	@catch (NSException *exception)
	{
		return NO;
	}
	return aPath != nil;
}

- (NSString *) stringValueForValue: (id)aValue
{
	return [(COPath *)aValue stringValue];
}

- (id) valueForStringValue: (NSString *)aString
{
	return [COPath pathWithString: aString];
}

- (BOOL) supportsRepresentationAsString
{
	return YES;
}

@end


@implementation COEmbeddedItemType (String)

- (BOOL) supportsRepresentationAsString
{
	return NO;
}

@end


@implementation COMultivaluedType (String)

- (BOOL) supportsRepresentationAsString
{
	return NO;
}

@end
