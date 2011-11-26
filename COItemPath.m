#import "COItemPath.h"
#import "Common.h"

@interface COItemPathToUnorderedContainer : COItemPath
@end

@interface COItemPathToOrderedContainer : COItemPath
{
	NSUInteger index;
}

- (id) initWithItemUUID: (ETUUID *)aUUID
			  arrayName: (NSString *)collection
				  index: (NSUInteger)anIndex;

@end



@implementation COItemPath

- (id) initWithItemUUID: (ETUUID *)aUUID
unorderedCollectionName: (NSString *)collection
{
	SUPERINIT
	ASSIGN(uuid, aUUID);
	ASSIGN(attribute, collection);
	return self;
}

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
		  unorderedCollectionName: (NSString *)collection
{
	return [[[COItemPathToUnorderedContainer alloc] initWithItemUUID: aUUID
											 unorderedCollectionName: collection] autorelease];
}

+ (COItemPath *) pathWithItemUUID: (ETUUID *)aUUID
						arrayName: (NSString *)collection
							index: (NSUInteger)index
{
	return [[[COItemPathToOrderedContainer alloc] initWithItemUUID: aUUID
														 arrayName: collection
															 index: index] autorelease];	
}

- (id)copyWithZone:(NSZone *)zone
{
	return [self retain];
}

- (void) insertValue: (id)aValue
		 inStoreItem: (COStoreItem *)aStoreItem
{	
	[NSException raise: NSInternalInconsistencyException
				format: @"%@ unimplemented", NSStringFromSelector(_cmd)];
}

@end



@implementation COItemPathToOrderedContainer

- (id) initWithItemUUID: (ETUUID *)aUUID
			  arrayName: (NSString *)collection
				  index: (NSUInteger)anIndex
{
	self = [super initWithItemUUID: aUUID
		   unorderedCollectionName: collection];
	if (self == nil)
		return nil;
	
	index = anIndex;
	
	return self;
}

- (void) insertValue: (id)aValue
		 inStoreItem: (COStoreItem *)aStoreItem
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

- (void) insertValue: (id)aValue
		 inStoreItem: (COStoreItem *)aStoreItem
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