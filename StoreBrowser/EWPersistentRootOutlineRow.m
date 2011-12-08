#import "EWPersistentRootOutlineRow.h"
#import "Common.h"

@implementation EWPersistentRootOutlineRow

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

- (ETUUID *)UUID
{
	return UUID;
}
- (NSString *)attribute
{
	return attribute;
}
- (NSArray *) buildContents
{	
	if (UUID == nil)
	{
		NSLog(@"WARNING: OutlineItem has no UUID (store probably has no root item)");
		return [NSArray array];
	}
	
	if (isPrimitiveInContainer)
	{
		return [NSArray array];
	}
	
	COStoreItem *storeItem = [ctx _storeItemForUUID: UUID];
	
	if (attribute == nil) // no attribute, so a root node for a persistent root
	{
		// return all attribute names, sorted alphabetically
		
		NSMutableArray *result = [NSMutableArray array];
		
		for (NSString *attr in [[storeItem attributeNames] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)])
		{
			EWPersistentRootOutlineRow *obj = [[EWPersistentRootOutlineRow alloc] initWithContext: ctx
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
		
		// if it is not a container type, and it is not an embedded item, it has no children
		if ([[type objectForKey: kCOTypeKind] isEqual: kCOPrimitiveTypeKind] &&
			![[type objectForKey: kCOPrimitiveType] isEqual: kCOPrimitiveTypeEmbeddedItem])
		{
			return [NSArray array];
		}
		
		// if it contains embedded objects, just return their UUIDs.
		if ([[type objectForKey: kCOPrimitiveType] isEqual: kCOPrimitiveTypeEmbeddedItem])
		{
			NSMutableArray *result = [NSMutableArray array];
			
			for (ETUUID *embeddedUUID in [storeItem allObjectsForAttribute: attribute])
			{
				EWPersistentRootOutlineRow *obj = [[EWPersistentRootOutlineRow alloc] initWithContext: ctx
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
				EWPersistentRootOutlineRow *obj = [[EWPersistentRootOutlineRow alloc] initWithContext: ctx
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
			// we are an attribute of an embedded object
			return attribute;
		}
		else			
		{
			COStoreItem *storeItem = [ctx _storeItemForUUID: UUID];
			id value = [storeItem valueForAttribute: @"name"];
			if (value) {
				return [NSString stringWithFormat: @"%@ (%@)", value, [storeItem UUID]];
			}
			
			return UUID;
		}
	}
	else if ([[column identifier] isEqualToString: @"value"])
	{
		if (attribute != nil)
		{
			COStoreItem *item = [ctx _storeItemForUUID: UUID];
			NSDictionary *type = [item typeForAttribute: attribute];
			
			if ([[type objectForKey: kCOTypeKind] isEqual: kCOPrimitiveTypeKind])
			{
				return [item valueForAttribute: attribute];
			}
		}
	}
	else if ([[column identifier] isEqualToString: @"type"])
	{
		COStoreItem *item = [ctx _storeItemForUUID: UUID];
		NSDictionary *type = [item typeForAttribute: attribute];

		if (isPrimitiveInContainer)
		{
			return [type objectForKey: kCOPrimitiveType];
		}
		else if (attribute != nil)
		{
			if ([[type objectForKey: kCOTypeKind] isEqual: kCOPrimitiveTypeKind])
			{
				return [type objectForKey: kCOPrimitiveType];
			}
			else
			{
				BOOL ordered = [[type objectForKey: kCOContainerOrdered] boolValue];
				BOOL allowsDuplicates = [[type objectForKey: kCOContainerAllowsDuplicates] boolValue];
				
				return [NSString stringWithFormat: @"(%@%@Container of %@)", 
						(ordered ? @"Ordered " : @"Unordered "),
						(allowsDuplicates ? @"" : @"Unique "),
						 [type objectForKey: kCOPrimitiveType]];
			}
		}
	}
	
	return nil;
}

- (NSImage *)image
{
	if (attribute == nil)
	{
		COStoreItem *item = [ctx _storeItemForUUID: UUID];
		if ([[item valueForAttribute: @"type"] isEqualToString: @"persistentRoot"])
		{
			return [NSImage imageNamed: @"package-x-generic"];
		}
		else if	([[item valueForAttribute: @"type"] isEqualToString: @"branch"])
		{
			return [NSImage imageNamed: @"branch"];
		}
		return [NSImage imageNamed: @"folder"];
	}
	else
	{
		return [NSImage imageNamed: @"text-x-generic"];
	}
}

@end

