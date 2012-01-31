#import "COItemPath.h"
#import "COItem.h"
#import "COMacros.h"
#import "COType.h"

@interface COItemPath (Private)

- (id) initWithItemUUID: (ETUUID *)aUUID
			  valueName: (NSString *)aName
				   type: (COType *)aType;

@end


@interface COItemPathToUnorderedContainer : COItemPath
@end

@interface COItemPathToOrderedContainer : COItemPath
{
	NSUInteger index;
}

- (id) initWithItemUUID: (ETUUID *)aUUID
			  arrayName: (NSString *)collection
		 insertionIndex: (NSUInteger)anIndex
				   type: (COType *)aType;

@end

@interface COItemPathToValue : COItemPath
@end



@implementation COItemPath

- (id) initWithItemUUID: (ETUUID *)aUUID
		  attributeName: (NSString *)aName
				   type: (COType *)aType
{
	SUPERINIT;
	ASSIGN(uuid, aUUID);
	ASSIGN(attribute, aName);
	ASSIGN(type, aType);
	return self;
}

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
		  unorderedCollectionName: (NSString *)collection
							 type: (COType *)aType
{
	return [[[COItemPathToUnorderedContainer alloc] initWithItemUUID: aUUID
													   attributeName: collection
																type: aType] autorelease];
}

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
						arrayName: (NSString *)collection
				   insertionIndex: (NSUInteger)index
							 type: (COType *)aType
{
	return [[[COItemPathToOrderedContainer alloc] initWithItemUUID: aUUID
														 arrayName: collection
													insertionIndex: index
															  type: aType] autorelease];	
}

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
						valueName: (NSString *)aName
							 type: (COType *)aType
{
	return [[[COItemPathToUnorderedContainer alloc] initWithItemUUID: aUUID
													   attributeName: aName
																type: aType] autorelease];	
}

- (void) dealloc
{
	[uuid release];
	[attribute release];
	[type release];
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
	return [self retain];
}

- (void) insertValue: (id)aValue
		 inStoreItem: (COMutableStoreItem *)aStoreItem
{	
	[NSException raise: NSInternalInconsistencyException
				format: @"%@ unimplemented", NSStringFromSelector(_cmd)];
}

- (BOOL) isEqual:(id)object
{
	if (![object isKindOfClass: [self class]])
		return NO;
	
	COItemPath *other = (COItemPath *)object;
	return ([uuid isEqual: other->uuid] &&
			[attribute isEqual: other->attribute]);
}

@end



@implementation COItemPathToOrderedContainer

- (id) initWithItemUUID: (ETUUID *)aUUID
			  arrayName: (NSString *)collection
		 insertionIndex: (NSUInteger)anIndex
				   type: (COType *)aType
{
	if ((self = [super initWithItemUUID: aUUID
						  attributeName: collection
								   type: type]) == nil)
	{
		return nil;
	}
	index = anIndex;
	return self;
}

- (void) insertValue: (id)aValue
			  ofType: (COType *)aType
		 inStoreItem: (COMutableStoreItem *)aStoreItem
{
	if (![aType isPrimitive])
	{
		[NSException raise: NSInvalidArgumentException
					format: @"expected primitive type"];
	}
	
	if (nil == [aStoreItem typeForAttribute: attribute])
	{
		[aStoreItem setType: [COType arrayWithPrimitiveType: aType]
			   forAttribute: attribute];		
	}
	else
	{
		if (![[aStoreItem typeForAttribute: attribute] isMultivalued] ||
			![[aStoreItem typeForAttribute: attribute] isOrdered] ||
			![[[aStoreItem typeForAttribute: attribute] primitiveType] isEqual: aType])
		{
			[NSException raise: NSInvalidArgumentException
						format: @"type mismatch"];
		}
	}
	
	NSMutableArray *array = [[NSMutableArray alloc] initWithArray: [aStoreItem valueForAttribute: attribute]];
	[array insertObject: aValue atIndex: index];
	[aStoreItem setValue: array forAttribute: attribute];
	[array release];
}

- (BOOL) isEqual:(id)object
{
	if (![object isKindOfClass: [self class]])
		return NO;
	
	COItemPathToOrderedContainer *other = (COItemPathToOrderedContainer *)object;
	return (index == other->index && [super isEqual: object]);
}

@end


@implementation COItemPathToUnorderedContainer

- (void) insertValue: (id)aValue
		 inStoreItem: (COMutableStoreItem *)aStoreItem
{
	assert([[aStoreItem typeForAttribute: attribute] isMultivalued]);
	assert(![[aStoreItem typeForAttribute: attribute] isOrdered]);
	
	NSMutableSet *set = [[aStoreItem valueForAttribute: attribute] mutableCopy]; // may be NSMutableSet subclass NSCountedSet
	assert([set isKindOfClass: [NSMutableSet class]]);
	[set addObject: aValue];
	[aStoreItem setValue: set forAttribute: attribute];
	[set release];
}

@end


@implementation COItemPathToValue

- (void) insertValue: (id)aValue
		 inStoreItem: (COMutableStoreItem *)aStoreItem
{
	// FIXME:
}

@end