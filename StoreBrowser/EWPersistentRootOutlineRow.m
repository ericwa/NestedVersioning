#import "EWPersistentRootOutlineRow.h"
#import "COMacros.h"

@implementation EWPersistentRootOutlineRow

- (EWPersistentRootOutlineRow *) parent
{
	return parent;
}

- (id) initWithContext: (COPersistentRootEditingContext *)aContext
			  itemUUID: (ETUUID *)aUUID
			 attribute: (NSString*)anAttribute
isPrimitiveInContainer: (BOOL)aFlag
				 index: (NSUInteger)anIndex
			   parent: (EWPersistentRootOutlineRow *)aParent
{
	SUPERINIT;
	ASSIGN(ctx, aContext);
	ASSIGN(UUID, aUUID);
	ASSIGN(attribute, anAttribute);
	isPrimitiveInContainer = aFlag;
	index = anIndex;
	parent = aParent;
	return self;
}

- (id) initWithContext: (COPersistentRootEditingContext *)aContext
			  itemUUID: (ETUUID *)aUUID
			 attribute: (NSString*)anAttribute
			   parent: (EWPersistentRootOutlineRow *)aParent
{
	return [self initWithContext: aContext
						itemUUID: aUUID
					   attribute: anAttribute 
		  isPrimitiveInContainer: NO
						   index: 0
						  parent: aParent];
}

- (id) initWithContext: (COPersistentRootEditingContext *)aContext
			  itemUUID: (ETUUID *)aUUID
			   parent: (EWPersistentRootOutlineRow *)aParent
{
	return [self initWithContext: aContext
						itemUUID: aUUID
					   attribute: nil 
		  isPrimitiveInContainer: NO
						   index: 0
						  parent: aParent];
}

- (id)initWithContext: (COPersistentRootEditingContext *)aContext
			   parent: (EWPersistentRootOutlineRow *)aParent
{
	return [self initWithContext: aContext
						itemUUID: [aContext rootUUID]
						  parent: aParent];
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
																						attribute: attr
																						   parent: self];
			[result addObject: obj];
			[obj release];
		}
		
		return result;
	}
	else // outlineitem specifies an attribute
	{
		COType *type = [storeItem typeForAttribute: attribute];
		
		if ([type isPrimitive] &&
			![type isEqual: [COType embeddedItemType]])
		{
			return [NSArray array];
		}
		
		// if it contains embedded objects, just return their UUIDs.
		if ([[type primitiveType] isEqual: [COType embeddedItemType]])
		{
			NSMutableArray *result = [NSMutableArray array];
			
			for (ETUUID *embeddedUUID in [storeItem allObjectsForAttribute: attribute])
			{
				EWPersistentRootOutlineRow *obj = [[EWPersistentRootOutlineRow alloc] initWithContext: ctx
																							 itemUUID: embeddedUUID
																							   parent: self];
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
																								index: i
																							   parent: self];
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
			COType *type = [item typeForAttribute: attribute];
			
			if ([type isPrimitive])
			{
				return [item valueForAttribute: attribute];
			}
		}
	}
	else if ([[column identifier] isEqualToString: @"type"])
	{
		COStoreItem *item = [ctx _storeItemForUUID: UUID];
		COType *type = [item typeForAttribute: attribute];

		if (isPrimitiveInContainer)
		{
			return [[type primitiveType] description];
		}
		else if (attribute != nil)
		{
			return [type description];
		}
		else
		{
			return [[COType embeddedItemType] description];
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

/**
 * Returns branches for given persistent root in an arbitrary
 * but stable sorted order
 */
- (NSArray *) orderedBranchesForUUID: (ETUUID*)aPersistentRoot
{
	return [[[ctx branchesOfPersistentRoot: aPersistentRoot] allObjects] sortedArrayUsingSelector: @selector(compare:)];
}

- (void) setValue: (id)object forTableColumn: (NSTableColumn *)tableColumn
{
	NSLog(@"Set to %@ col %@", object, [tableColumn identifier]);
	
	if ([[tableColumn identifier] isEqualToString: @"currentbranch"])
	{
		ETUUID *selectedBranch = [[self orderedBranchesForUUID: [self UUID]] objectAtIndex: [object integerValue]];
		[ctx setCurrentBranch: selectedBranch
			forPersistentRoot: [self UUID]];
		[ctx commitWithMetadata: nil];
		
		[[NSApp delegate] reloadAllBrowsers];
	}
	if ([[tableColumn identifier] isEqualToString: @"value"])
	{
		if ([self attribute] != nil)
		{
			NSLog(@"Attempting to store new value '%@' for attribute '%@' of %@",
				  object, [self attribute], [self UUID]);
			
			COStoreItem *storeItem = [ctx _storeItemForUUID: [self UUID]];
			
			// FIXME: won't work for multivalued properties..
			// FIXME: will currently only work for strings..
			
			[storeItem setValue: object
				   forAttribute: [self attribute]];
			[ctx _insertOrUpdateItems: S(storeItem)];
			[ctx commitWithMetadata: nil];
			
			[[NSApp delegate] reloadAllBrowsers];
		}
	}	
}

@end

