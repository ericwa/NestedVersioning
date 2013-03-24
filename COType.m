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
                      [COAttachmentType type],
                      [COReferenceType type],
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

@implementation COUUIDType
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

@implementation COAttachmentType

- (NSString *)stringValue
{
	return @"Attachment";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [NSData class]];
}

@end

@implementation COReferenceType

- (NSString *)stringValue
{
	return @"Reference";
}

- (BOOL) validateValue: (id)aValue
{
	return [aValue isKindOfClass: [COUUID class]];
}

@end

@implementation COMultivaluedType

- (id) initWithPrimitiveType: (COType*)aType
				   isOrdered: (BOOL)isOrdered
{
	if (![aType isKindOfClass: [COPrimitiveType class]])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"%@ is not a primitive type", aType];
	}
	
	SUPERINIT;
	ASSIGN(primitiveType, aType);
	ordered = isOrdered;	return self;
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
	
	if (!ordered)
	{
		prefix = @"Set of ";
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
	
	if (!ordered)
	{
		suffix = @"-Set";
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
	
	BOOL isOrdered;
	
	if ([suffixString isEqualToString: @"-Set"])
	{
		isOrdered = NO;
	}
	else if ([suffixString isEqualToString: @"-Array"])
	{
		isOrdered = YES;
	}
	else
	{
		return nil;
	}
	
	return [[[COMultivaluedType alloc] initWithPrimitiveType: primitive
												   isOrdered: isOrdered] autorelease];
}

- (BOOL) validateValue: (id)aValue
{
	BOOL valid;
	
	if (!ordered)
	{
		valid = [aValue isKindOfClass: [NSSet class]];
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
			&& ordered == otherType->ordered);
}

- (COType *) primitiveType
{
	return primitiveType;
}

- (BOOL) isOrdered
{
	return ordered;
}

@end

@implementation CONamedType

@synthesize name;

- (id)initWithName: (NSString *)aName storageType: (COType *)stype
{
    SUPERINIT;
    self.name = aName;
    self.storageType = stype;
    return self;
}

- (void)dealloc
{
    [self.name release];
    [self.storageType release];
    [super dealloc];
}

+ (COType*) typeWithString: (NSString *)aTypeString
{
    if ([aTypeString hasPrefix: @"{"])
    {
        NSRange separator = [aTypeString rangeOfString: @":"];
        if (separator.location == NSNotFound)
        {
            return nil;
        }
        
        NSString *name = [aTypeString substringToIndex: separator.location];
        NSString *suffixString = [aTypeString substringWithRange:
                                  NSMakeRange(separator.location + 1, [aTypeString length] - (separator.location + 1))];
        return [[[self alloc] initWithName: name
                               storageType: [COType typeWithString: suffixString]] autorelease];
    }
    return nil;
}

- (BOOL) isMultivalued
{
	return [self.storageType isMultivalued];
}

- (BOOL) isPrimitive
{
    return [self.storageType isPrimitive];
}

- (BOOL) validateValue: (id)aValue
{
	return [self.storageType validateValue: aValue];
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"{%@:%@}", self.name, self.storageType];
}

- (NSString *) stringValue
{
	return [NSString stringWithFormat: @"{%@:%@}", self.name, [self.storageType stringValue]];
}

- (COType *) primitiveType
{
    return [[self storageType] primitiveType];
}

- (BOOL) isOrdered
{
    return [[self storageType] isOrdered];
}

- (BOOL) isEqual: (id)object
{
    if (![object isKindOfClass: [CONamedType class]]) return NO;
    return [self.name isEqual: ((CONamedType *)object).name] && [[self storageType] isEqual: ((CONamedType *)object).storageType];
}

- (id) copyWithZone:(NSZone *)zone
{
	return [self retain];
}

- (BOOL) isPrimitiveTypeEqual: (id)object
{
    return [self.storageType isPrimitiveTypeEqual: object];
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

+ (COType *) attachmentType
{
    return [COAttachmentType type];
}

+ (COType *) referenceType
{
    return [COReferenceType type];
}

- (COType *) setType
{
    return [[[COMultivaluedType alloc]
			 initWithPrimitiveType: self
			 isOrdered: NO] autorelease];
}
- (COType *) arrayType
{
	return [[[COMultivaluedType alloc]
			 initWithPrimitiveType: self
			 isOrdered: YES] autorelease];
}

- (COType *) namedType: (NSString *)aName
{
    return [[[CONamedType alloc] initWithName: aName storageType: self] autorelease];
}
- (COType *) storageType // Type ignoring name
{
    return self;
}
- (NSString *) name
{
    return nil;
}
+ (COType*) typeWithString: (NSString *)aTypeString
{
	NILARG_EXCEPTION_TEST(aTypeString);

	COType *result = [CONamedType typeWithString: aTypeString];
	if (result == nil)
    {
        result = [COMultivaluedType typeWithString: aTypeString];
    }
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
