#import "COItemPath.h"
#import "COMacros.h"

@interface COItemPathToUnorderedContainer : COItemPath
{
}

- (id) initWithItemUUID: (ETUUID *)aUUID
unorderedCollectionName: (NSString *)collection;

@end

@interface COItemPathToOrderedContainer : COItemPath
{
	NSUInteger index;
}

- (id) initWithItemUUID: (ETUUID *)aUUID
			  arrayName: (NSString *)collection
		 insertionIndex: (NSUInteger)anIndex;

@end



@implementation COItemPath

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
		  unorderedCollectionName: (NSString *)collection
{
	return [[[COItemPathToUnorderedContainer alloc] initWithItemUUID: aUUID
											 unorderedCollectionName: collection] autorelease];
}

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
						arrayName: (NSString *)collection
				   insertionIndex: (NSUInteger)index
{
	return [[[COItemPathToOrderedContainer alloc] initWithItemUUID: aUUID
														 arrayName: collection
													insertionIndex: index] autorelease];	
}

- (void) dealloc
{
	[uuid release];
	[attribute release];
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

@end



@implementation COItemPathToOrderedContainer

- (id) initWithItemUUID: (ETUUID *)aUUID
			  arrayName: (NSString *)collection
		 insertionIndex: (NSUInteger)anIndex
{
	SUPERINIT
	ASSIGN(uuid, aUUID);
	ASSIGN(attribute, collection);
	index = anIndex;
	return self;
}

- (void) insertValue: (id)aValue
		 inStoreItem: (COMutableStoreItem *)aStoreItem
{
	assert([[[aStoreItem typeForAttribute: attribute] objectForKey: kCOTypeKind] isEqual: kCOContainerTypeKind]);
	assert([[[aStoreItem typeForAttribute: attribute] objectForKey: kCOContainerOrdered] isEqual: [NSNumber numberWithBool: YES]]);
	
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
	return ([uuid isEqual: other->uuid] && 
			[attribute isEqual: other->attribute] &&
			index == other->index);
}

@end


@implementation COItemPathToUnorderedContainer

- (id) initWithItemUUID: (ETUUID *)aUUID
unorderedCollectionName: (NSString *)collection
{
	SUPERINIT
	ASSIGN(uuid, aUUID);
	ASSIGN(attribute, collection);
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) insertValue: (id)aValue
		 inStoreItem: (COMutableStoreItem *)aStoreItem
{
	assert([[[aStoreItem typeForAttribute: attribute] objectForKey: kCOTypeKind] isEqual: kCOContainerTypeKind]);
	assert([[[aStoreItem typeForAttribute: attribute] objectForKey: kCOContainerOrdered] isEqual: [NSNumber numberWithBool: NO]]);
	
	NSMutableSet *set = [[aStoreItem valueForAttribute: attribute] mutableCopy]; // may be NSMutableSet subclass NSCountedSet
	assert([set isKindOfClass: [NSMutableSet class]]);
	[set addObject: aValue];
	[aStoreItem setValue: set forAttribute: attribute];
	[set release];
}

- (BOOL) isEqual:(id)object
{
	if (![object isKindOfClass: [self class]])
		return NO;
	
	COItemPathToUnorderedContainer *other = (COItemPathToUnorderedContainer *)object;
	return ([uuid isEqual: other->uuid] &&
			[attribute isEqual: other->attribute]);
}

@end