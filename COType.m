#import "COType.h"
#import "Common.h"
#import "ETUUID.h"
#import "COPath.h"
#import "COTypePrivate.h"

@implementation COPrimitiveType

+ (COType *)type
{
	return [[[[self class] alloc] init] autorelease];
}

- (BOOL) isMultivalued
{
	return NO;
}
- (BOOL) isPrimitive
{
	return YES;
}

@end

@implementation COInt64Type

- (NSString *)description
{
	return @"Int";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [NSNumber class]];
}

@end


@implementation CODoubleType

- (NSString *)description
{
	return @"Double";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [NSNumber class]];
}

@end


@implementation COStringType

- (NSString *)description
{
	return @"String";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [NSString class]];
}

@end


@implementation COFullTextIndexableStringType

- (NSString *)description
{
	return @"Indexable String";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [NSNumber class]];
}

@end


@implementation COBlobType

- (NSString *)description
{
	return @"Blob";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [NSData class]];
}

@end


@implementation COCommitType

- (NSString *)description
{
	return @"Commit Ref";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [ETUUID class]];
}

@end


@implementation COPathType

- (NSString *)description
{
	return @"Path";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [COPath class]];
}

@end


@implementation COEmbeddedItemType

- (NSString *)description
{
	return @"Embedded Item";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [ETUUID class]];
}

@end



@implementation COMultivaluedType

- (id) initWithPrimitiveType: (COPrimitiveType*)aType
				   isOrdered: (BOOL)isOrdered
					isUnique: (BOOL)isUnique
{
	NILARG_EXCEPTION_TEST(aType);
	
	SUPERINIT;
	ASSIGN(primitive, aType);
	ordered = isOrdered;
	unique = isUnique;
	return self;
}

- (void) dealloc
{
	[primitive release];
	[super dealloc];
}

- (BOOL) isMultivalued
{
	return YES;
}
- (BOOL) isPrimitive
{
	return NO;
}

- (NSString *)description
{
	NSString *prefix;
	
	if (!ordered && unique)
	{
		prefix = @"Set of ";
	}
	else if (!ordered && !unique)
	{
		prefix = @"Bag of ";
	}
	else if (ordered && unique)
	{
		prefix = @"Unique Array of ";
	}
	else
	{
		prefix = @"Array of ";
	}			
	
	return [prefix stringByAppendingString: [primitive description]];
}

- (BOOL) validateValue: (id)aValue
{
	BOOL valid;
	
	if (!orderedVal && unique)
	{
		valid = [aValue isKindOfClass: [NSSet class]] && 
			![aValue isKindOfClass: [NSCountedSet class]];
	}
	else if (!orderedVal && !unique)
	{
		valid = [aValue isKindOfClass: [NSCountedSet class]];			
	}
	else if (orderedVal && unique)
	{
		if ([aValue isKindOfClass: [NSArray class]])
		{
			NSSet *set = [[NSSet alloc] initWithArray: aValue];
			valid = ([set count] == [aValue count]);
			[set release];
		}
		else
		{
			valid = NO;
		}
	}
	else
	{
		valid = [aValue isKindOfClass: [NSArray class]];
	}
	
	for (id obj in aValue)
	{
		valid = valid && [primitive validateValue: obj];
	}
	
	return valid;
}

@end




@implementation COType

+ (COType *) int64Type
{
	return [COInt64Type type];
}

+ (COType *) doubleType
{
	return [CODoubleType type];
}

+ (COType *) stringType
{
	return [COStringType type];
}

+ (COType *) fullTextIndexableStringType
{
	return [COFullTextIndexableStringType type];
}

+ (COType *) blobType
{
	return [COBlobType type];
}

+ (COType *) commitUUIDType
{
	return [COCommitType type];
}

+ (COType *) pathType
{
	return [COPathType type];
}

+ (COType *) embeddedItemType
{
	return [COEmbeddedItemType type];
}

+ (COType *) setWithPrimitiveType: (COType *)aType
{
	return [[[COMultivaluedType alloc]
			 initWithPrimitiveType: aType
			 isOrdered: NO
			 isUnique: YES] autorelease];
}

+ (COType *) bagWithPrimitiveType: (COType *)aType
{
	return [[[COMultivaluedType alloc]
			 initWithPrimitiveType: aType
			 isOrdered: NO
			 isUnique: NO] autorelease];	
}

+ (COType *) arrayWithPrimitiveType: (COType *)aType
{
	return [[[COMultivaluedType alloc]
			 initWithPrimitiveType: aType
			 isOrdered: YES
			 isUnique: NO] autorelease];
}

+ (COType *) uniqueArrayWithPrimitiveType: (COType *)aType
{
	return [[[COMultivaluedType alloc]
			 initWithPrimitiveType: aType
			 isOrdered: YES
			 isUnique: YES] autorelease];
}

- (BOOL) isMultivalued
{
	[NSException raise: NSInternalInconsistencyException
				format: @"%@ unimplemented", NSStringFromSelector(_cmd)];
}

- (BOOL) isPrimitive
{
	[NSException raise: NSInternalInconsistencyException
				format: @"%@ unimplemented", NSStringFromSelector(_cmd)];
}

- (BOOL) validateValue: (id)aValue
{
	[NSException raise: NSInternalInconsistencyException
				format: @"%@ unimplemented", NSStringFromSelector(_cmd)];
}

- (NSString *) description
{
	[NSException raise: NSInternalInconsistencyException
				format: @"%@ unimplemented", NSStringFromSelector(_cmd)];
}

- (id) copyWithZone:(NSZone *)zone
{
	return [self retain];
}

@end
