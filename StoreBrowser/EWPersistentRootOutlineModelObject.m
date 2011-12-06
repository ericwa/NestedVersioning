#import "EWPersistentRootOutlineModelObject.h"
#import "Common.h"

@implementation EWPersistentRootOutlineModelObject

- (id) initWithContext: (COPersistentRootEditingContext *)aContext
			  itemUUID: (ETUUID *)aUUID
			 attribute: (NSString*)anAttribute
isPrimitiveInContainer: (BOOL)aFlag
				 index: (NSUInteger)anIndex
{
	SUPERINIT;
	ASSIGN(ctx, aContext);
	ASSIGN(UUID, aUUID);
	ASSIGN(attribute, anAttribute);
	isPrimitiveInContainer = aFlag;
	index = anIndex;
	return self;
}

- (id) initWithContext: (COPersistentRootEditingContext *)aContext
			  itemUUID: (ETUUID *)aUUID
			 attribute: (NSString*)anAttribute
{
	return [self initWithContext: aContext
						itemUUID: aUUID
					   attribute: anAttribute 
		  isPrimitiveInContainer: NO
						   index: 0];
}

- (id) initWithContext: (COPersistentRootEditingContext *)aContext
			  itemUUID: (ETUUID *)aUUID
{
	return [self initWithContext: aContext
						itemUUID: aUUID
					   attribute: nil 
		  isPrimitiveInContainer: NO
						   index: 0];
}

- (id)initWithContext: (COPersistentRootEditingContext *)aContext
{
	return [self initWithContext: aContext
						itemUUID: [aContext rootUUID]];
}

- (void)dealloc
{
	[ctx release];
	[UUID release];
	[attribute release];
	[contents release];
	[super dealloc];
}

- (NSArray *) buildContents
{	
	if (UUID == nil)
	{
		NSLog(@"WARNING: OutlineItem has no UUID (store probably has no root item)");
		return [NSArray array];
	}
	
	COStoreItem *storeItem = [ctx _storeItemForUUID: UUID];
	
	if (attribute == nil) // no attribute, so a root node for a persistent root
	{
		// return all attribute names, sorted alphabetically
		
		NSMutableArray *result = [NSMutableArray array];
		
		for (NSString *attr in [[storeItem attributeNames] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)])
		{
			EWPersistentRootOutlineModelObject *obj = [[EWPersistentRootOutlineModelObject alloc] initWithContext: ctx
																										 itemUUID: UUID
																										attribute: attr];
			[result addObject: obj];
			[obj release];
		}
		
		return result;
	}
	else // outlineitem specifies an attribute
	{
		NSDictionary *type = [storeItem typeForAttribute: attribute];
		
		// if it contains embedded objects, just return their UUIDs.
		if ([[type objectForKey: kCOPrimitiveType] isEqual: kCOPrimitiveTypeEmbeddedItem])
		{
			NSMutableArray *result = [NSMutableArray array];
			
			for (ETUUID *embeddedUUID in [storeItem allObjectsForAttribute: attribute])
			{
				EWPersistentRootOutlineModelObject *obj = [[EWPersistentRootOutlineModelObject alloc] initWithContext: ctx
																											 itemUUID: embeddedUUID];
				[result addObject: obj];
				[obj release];
			}
			return result;
		}
		else // it contains primitive types, which will be leaf nodes
		{
			NSMutableArray *result = [NSMutableArray array];
			
			const NSUInteger count = [[storeItem allObjectsForAttribute: attribute] count];
			for (NSUInteger i=0; i<count; i++)
			{
				EWPersistentRootOutlineModelObject *obj = [[EWPersistentRootOutlineModelObject alloc] initWithContext: ctx
																											 itemUUID: UUID
																											attribute: attribute
																							   isPrimitiveInContainer: YES
																												index: i];
				[result addObject: obj];
				[obj release];
			}
			
			return result;
		}
	}	
}

- (NSArray*)children
{
	if (contents == nil)
	{
		ASSIGN(contents, [self buildContents]);
	}
	assert(contents != nil);
	return contents;
}

- (id)valueForTableColumn: (NSTableColumn *)column
{
	if ([[column identifier] isEqualToString: @"name"])
	{
		if (isPrimitiveInContainer)
		{
			COStoreItem *storeItem = [ctx _storeItemForUUID: UUID];
			id value = [[storeItem allObjectsForAttribute: attribute] objectAtIndex: index];
			return value;
		}
		else if (attribute != nil)
		{
			return attribute;
		}
		else			
		{
			return UUID;
		}
	}
	else
	{
		return @"";
	}
}


@end

