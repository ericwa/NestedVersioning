#import "COType.h"
#import "COMacros.h"
#import "COUUID.h"
#import "COPath.h"
#import "COTypePrivate.h"

@implementation COPrimitiveType

+ (COType *)type
{
	static NSMutableDictionary *typeDictionary;
	if (typeDictionary == nil)
	{
		typeDictionary = [[NSMutableDictionary alloc] init];
	}
	
	COType *singleton = [typeDictionary objectForKey: NSStringFromClass([self class])];
	
	if (singleton == nil)
	{
		singleton = [[[self class] alloc] init];
		[typeDictionary setObject: singleton
						   forKey: NSStringFromClass([self class])];
		[singleton release];
	}
	
	return singleton;
}

- (BOOL) isMultivalued
{
	return NO;
}
- (BOOL) isPrimitive
{
	return YES;
}

/**
 * Primitive types have no state so equality is based on class
 */
- (BOOL) isEqual: (id)object
{
	return [self isKindOfClass: [object class]];
}

- (COType *) primitiveType
{
	return self;
}

- (NSString *) description
{
	return [self stringValue];
}

+ (COType*) typeWithString: (NSString *)aTypeString
{
	NILARG_EXCEPTION_TEST(aTypeString);

	NSArray *types = [NSArray arrayWithObjects:
						[COInt64Type type],
					  [CODoubleType type],
					  [COStringType type],
					  [COFullTextIndexableStringType type],
					  [COBlobType type],
					  [COCommitType type],
					  [COPathType type],
					  [COEmbeddedItemType type],
					  nil];

	for (COType *type in types)
	{
		if ([[type stringValue] isEqualToString: aTypeString])
			return type;
	}
	return nil;
}

@end

@implementation COInt64Type

- (NSString *)stringValue
{
	return @"Int";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [NSNumber class]];
}

@end


@implementation CODoubleType

- (NSString *)stringValue
{
	return @"Double";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [NSNumber class]];
}

@end


@implementation COStringType

- (NSString *)stringValue
{
	return @"String";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [NSString class]];
}

@end


@implementation COFullTextIndexableStringType

- (NSString *)stringValue
{
	return @"IndexableString";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [NSNumber class]];
}

@end


@implementation COBlobType

- (NSString *)stringValue
{
	return @"Blob";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [NSData class]];
}

@end


@implementation COCommitType

- (NSString *)stringValue
{
	return @"Commit";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [COUUID class]];
}

@end


@implementation COPathType

- (NSString *)stringValue
{
	return @"Path";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [COPath class]];
}

@end


@implementation COEmbeddedItemType

- (NSString *)stringValue
{
	return @"EmbeddedItem";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [COUUID class]];
}

@end



@implementation COMultivaluedType

- (id) initWithPrimitiveType: (COType*)aType
				   isOrdered: (BOOL)isOrdered
					isUnique: (BOOL)isUnique
{
	if (![aType isKindOfClass: [COPrimitiveType class]])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"%@ is not a primitive type", aType];
	}
	if ([aType isEqual: [COType embeddedItemType]] && !isUnique)
	{
		[NSException raise: NSInvalidArgumentException
					format: @"[COType embeddedItemType] can only exist in a unique multivalue"];
	}
	
	SUPERINIT;
	ASSIGN(primitiveType, aType);
	ordered = isOrdered;
	unique = isUnique;
	return self;
}

- (void) dealloc
{
	[primitiveType release];
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
	
	return [prefix stringByAppendingString: [primitiveType description]];
}

- (NSString *)stringValue
{
	NSString *suffix;
	
	if (!ordered && unique)
	{
		suffix = @"-Set";
	}
	else if (!ordered && !unique)
	{
		suffix = @"-Bag ";
	}
	else if (ordered && unique)
	{
		suffix = @"-UniqueArray";
	}
	else
	{
		suffix = @"-Array";
	}			
	
	return [[primitiveType stringValue] stringByAppendingString: suffix];
}

+ (COType*) typeWithString: (NSString *)aTypeString
{
	NILARG_EXCEPTION_TEST(aTypeString);
		
	NSRange separator = [aTypeString rangeOfString: @"-"];
	if (separator.location == NSNotFound)
	{
		return nil;
	}
	
	NSString *primitiveString = [aTypeString substringToIndex: separator.location];
	COType *primitive = [COPrimitiveType typeWithString: primitiveString];
	NSString *suffixString = [aTypeString substringFromIndex: separator.location];
	
	BOOL isOrdered, isUnique;
	
	if ([suffixString isEqualToString: @"-Set"])
	{
		isOrdered = NO; isUnique = YES;
	}
	else if ([suffixString isEqualToString: @"-Bag"])
	{
		isOrdered = NO; isUnique = NO;
	}
	else if ([suffixString isEqualToString: @"-UniqueArray"])
	{
		isOrdered = YES; isUnique = YES;
	}
	else if ([suffixString isEqualToString: @"-Array"])
	{
		isOrdered = YES; isUnique = NO;
	}
	else
	{
		return nil;
	}
	
	return [[[COMultivaluedType alloc] initWithPrimitiveType: primitive
												   isOrdered: isOrdered
													isUnique: isUnique] autorelease];
}

- (BOOL) validateValue: (id)aValue
{
	BOOL valid;
	
	if (!ordered && unique)
	{
		valid = [aValue isKindOfClass: [NSSet class]] && 
			![aValue isKindOfClass: [NSCountedSet class]];
	}
	else if (!ordered && !unique)
	{
		valid = [aValue isKindOfClass: [NSCountedSet class]];			
	}
	else if (ordered && unique)
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
		valid = valid && [primitiveType validateValue: obj];
	}
	
	return valid;
}

- (BOOL) isEqual: (id)object
{
	if (![object isKindOfClass: [self class]])
		return NO;
	COMultivaluedType *otherType = (COMultivaluedType *)object;
	return ([primitiveType isEqual: otherType->primitiveType] 
			&& ordered == otherType->ordered
			&& unique == otherType->unique);
}

- (COType *) primitiveType
{
	return primitiveType;
}

- (BOOL) isOrdered
{
	return ordered;
}
- (BOOL) isUnique
{
	return unique;
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

+ (COType*) typeWithString: (NSString *)aTypeString
{
	NILARG_EXCEPTION_TEST(aTypeString);
	
	COType *result = [COMultivaluedType typeWithString: aTypeString];
	if (result == nil)
	{
		result = [COPrimitiveType typeWithString: aTypeString];
	}
	
	if (result == nil)
	{
		[NSException raise: NSInvalidArgumentException
					format: @"'%@' is not a valid string representation of a type", aTypeString];
	}
	
	return result;
}

- (BOOL) isMultivalued
{
	[NSException raise: NSInternalInconsistencyException
				format: @"%@ unimplemented", NSStringFromSelector(_cmd)];
	return NO;
}

- (BOOL) isPrimitive
{
	[NSException raise: NSInternalInconsistencyException
				format: @"%@ unimplemented", NSStringFromSelector(_cmd)];
	return NO;
}

- (BOOL) validateValue: (id)aValue
{
	[NSException raise: NSInternalInconsistencyException
				format: @"%@ unimplemented", NSStringFromSelector(_cmd)];
	return NO;
}

- (NSString *) description
{
	[NSException raise: NSInternalInconsistencyException
				format: @"%@ unimplemented", NSStringFromSelector(_cmd)];
	return nil;
}

- (NSString *) stringValue
{
	[NSException raise: NSInternalInconsistencyException
				format: @"%@ unimplemented", NSStringFromSelector(_cmd)];
	return nil;
}


- (COType *) primitiveType
{
	[NSException raise: NSInternalInconsistencyException
				format: @"%@ unimplemented", NSStringFromSelector(_cmd)];
	return nil;
}

- (BOOL) isOrdered
{
	[NSException raise: NSInternalInconsistencyException
				format: @"%@ unimplemented", NSStringFromSelector(_cmd)];
	return NO;
}

- (BOOL) isUnique
{
	[NSException raise: NSInternalInconsistencyException
				 format: @"%@ unimplemented", NSStringFromSelector(_cmd)];
	return NO;
}

- (BOOL) isEqual: (id)object
{
	[NSException raise: NSInternalInconsistencyException
				format: @"%@ unimplemented", NSStringFromSelector(_cmd)];
	return NO;
}

- (id) copyWithZone:(NSZone *)zone
{
	return [self retain];
}

- (BOOL) isPrimitiveTypeEqual: (id)object
{
	if (![object isPrimitive])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"expected a primitive type as an argument"];
	}
	return [[self primitiveType] isEqual: object];
}

@end
