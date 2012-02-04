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
		 inStoreItem: (COMutableItem *)aStoreItem
{	
	[NSException raise: NSInternalInconsistencyException
				format: @"%@ unimplemented", NSStringFromSelector(_cmd)];
}

- (void) removeValue: (id)aValue inStoreItem: (COMutableItem *)aStoreItem
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

- (ETUUID *)UUID
{
	return uuid;
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
		 inStoreItem: (COMutableItem *)aStoreItem
{
	[aStoreItem addObject: aValue 
	   toOrderedAttribute: attribute
				  atIndex: index
					 type: type];
}

- (void) removeValue: (id)aValue inStoreItem: (COMutableItem *)aStoreItem
{
	NSMutableArray *array = [aStoreItem valueForAttribute: attribute];
	NSAssert([[array objectAtIndex: index] isEqual: aValue], @"value being removed is not what was expected.");
	[array removeObjectAtIndex: index];
	[aStoreItem setValue: array forAttribute: attribute];
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
		 inStoreItem: (COMutableItem *)aStoreItem
{
	[aStoreItem addObject: aValue
	 toUnorderedAttribute: attribute
					 type: type];
}

- (void) removeValue: (id)aValue inStoreItem: (COMutableItem *)aStoreItem
{
	NSMutableSet *set = [aStoreItem valueForAttribute: attribute];
	NSAssert([set containsObject: aValue], @"value to be remove is not present in set");
	[set removeObject: aValue];
	[aStoreItem setValue: set forAttribute: attribute];
}

@end


@implementation COItemPathToValue

- (void) insertValue: (id)aValue
		 inStoreItem: (COMutableItem *)aStoreItem
{
	[aStoreItem setValue: aValue
			forAttribute: attribute
					type: type];
}

- (void) removeValue: (id)aValue inStoreItem: (COMutableItem *)aStoreItem
{
	NSAssert([[aStoreItem valueForAttribute: attribute] isEqual: aValue], @"value to be removed is not what was expected");
	[aStoreItem removeValueForAttribute: attribute];
}

@end