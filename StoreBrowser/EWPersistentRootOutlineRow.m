#import "EWPersistentRootOutlineRow.h"
#import "COMacros.h"
#import "COType+String.h"
#import "EWPersistentRootWindowController.h"

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
	  windowController: (EWPersistentRootWindowController *)aController
{
	SUPERINIT;
	ASSIGN(ctx, aContext);
	ASSIGN(UUID, aUUID);
	ASSIGN(attribute, anAttribute);
	isPrimitiveInContainer = aFlag;
	index = anIndex;
	parent = aParent;
	windowController = aController;
	return self;
}

- (BOOL) isPrimitiveInContainer
{
	return isPrimitiveInContainer;
}

// Special row types

- (BOOL) isPersistentRoot
{
	COMutableItem *item = [ctx _storeItemForUUID: UUID];
	if (attribute == nil)
	{		
		return [[item valueForAttribute: @"type"] isEqualToString: @"persistentRoot"];
	}
	return NO;
}
- (BOOL) isBranch
{
	COMutableItem *item = [ctx _storeItemForUUID: UUID];
	if (attribute == nil)
	{		
		return [[item valueForAttribute: @"type"] isEqualToString: @"branch"];
	}
	return NO;
}
- (BOOL) isEmbeddedObject
{
	return attribute == nil;
}


- (id) initWithContext: (COPersistentRootEditingContext *)aContext
			  itemUUID: (ETUUID *)aUUID
			 attribute: (NSString*)anAttribute
				parent: (EWPersistentRootOutlineRow *)aParent
	  windowController: (EWPersistentRootWindowController *)aController
{
	return [self initWithContext: aContext
						itemUUID: aUUID
					   attribute: anAttribute 
		  isPrimitiveInContainer: NO
						   index: 0
						  parent: aParent
				windowController: aController];
}

- (id) initWithContext: (COPersistentRootEditingContext *)aContext
			  itemUUID: (ETUUID *)aUUID
				parent: (EWPersistentRootOutlineRow *)aParent
	  windowController: (EWPersistentRootWindowController *)aController
{
	return [self initWithContext: aContext
						itemUUID: aUUID
					   attribute: nil 
		  isPrimitiveInContainer: NO
						   index: 0
						  parent: aParent
				windowController: aController];
}

- (id)initWithContext: (COPersistentRootEditingContext *)aContext
			   parent: (EWPersistentRootOutlineRow *)aParent
	 windowController: (EWPersistentRootWindowController *)aController
{
	return [self initWithContext: aContext
						itemUUID: [aContext rootUUID]
						  parent: aParent
				windowController: aController];
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
	
	COMutableItem *storeItem = [ctx _storeItemForUUID: UUID];
	
	if ([self isEmbeddedObject]) // no attribute, so a root node for a persistent root
	{
		// return all attribute names, sorted alphabetically
		
		NSMutableArray *result = [NSMutableArray array];
		
		for (NSString *attr in [storeItem attributeNames])
		{
			EWPersistentRootOutlineRow *obj = [[EWPersistentRootOutlineRow alloc] initWithContext: ctx
																						 itemUUID: UUID
																						attribute: attr
																						   parent: self
																				 windowController: windowController];
			[result addObject: obj];
			[obj release];
		}
		
		[result sortUsingSelector: @selector(compare:)];
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
																							   parent: self
																					 windowController: windowController];
				[result addObject: obj];
				[obj release];
			}
			
			[result sortUsingSelector: @selector(compare:)];
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
																							   parent: self
																					 windowController: windowController];
				[result addObject: obj];
				[obj release];
			}
			
			[result sortUsingSelector: @selector(compare:)];
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
			COMutableItem *storeItem = [ctx _storeItemForUUID: UUID];
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
			COMutableItem *storeItem = [ctx _storeItemForUUID: UUID];
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
			COMutableItem *item = [ctx _storeItemForUUID: UUID];
			COType *type = [item typeForAttribute: attribute];
			
			if ([type isPrimitive])
			{
				return [item valueForAttribute: attribute];
			}
		}
	}
	else if ([[column identifier] isEqualToString: @"type"])
	{
		COMutableItem *item = [ctx _storeItemForUUID: UUID];
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
	else if ([[column identifier] isEqualToString: @"currentbranch"])
	{
		if ([self isPersistentRoot])
		{
			// NSPopupButtonCell takes a NSNumber indicating the index in the menu.
			
			NSArray *branches = [self orderedBranchesForUUID: [self UUID]];
			
			ETUUID *current = [ctx currentBranchOfPersistentRoot: [self UUID]];
			
			NSUInteger i = [branches indexOfObject: current];
			assert(i < [branches count]);
			
			return [NSNumber numberWithInt: i];
		}
		return nil;
	}
	
	return nil;
}

- (NSImage *)image
{
	COMutableItem *item = [ctx _storeItemForUUID: UUID];
	if ([self isEmbeddedObject])
	{		
		if ([self isPersistentRoot])
		{
			return [NSImage imageNamed: @"package"]; // persistent root embedded object
		}
		else if	([self isBranch])
		{
			return [NSImage imageNamed: @"arrow_branch"]; // branch embedded object
		}
		return [NSImage imageNamed: @"brick"]; // regular embedded object
	}
	else
	{
		COType *type = [item typeForAttribute: attribute];
		
		if ([type isPrimitive])
		{
			return [NSImage imageNamed: @"bullet_yellow"]; // primitive attribute
		}
		else
		{
			return [NSImage imageNamed: @"bullet_purple"]; // multivalued attribute
		}
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
			
			COMutableItem *storeItem = [ctx _storeItemForUUID: [self UUID]];
			
			COType *type = [storeItem typeForAttribute: [self attribute]];
			
			if (![type supportsRepresentationAsString])
			{
				NSLog(@"Type does not support setting from a string");
				return;
			}
			
			BOOL valid = [type isValidStringValue: object];
			if (!valid)
			{
				NSLog(@"%@ not a valid string value for type %@", object, type);
				return;
			}
			
			id value = [type valueForStringValue: object]; // e.g. converts string -> ETUUID
			
			[storeItem setValue: value
				   forAttribute: [self attribute]];
			[ctx _insertOrUpdateItems: S(storeItem)];
			[ctx commitWithMetadata: nil];
			
			[[NSApp delegate] reloadAllBrowsers];
		}
	}	
}

- (NSCell *)dataCellForTableColumn: (NSTableColumn *)tableColumn
{
	if ([self attribute] == nil) // only if we click on the root of an embedded object
	{
		COMutableItem *storeItem = [ctx _storeItemForUUID: [self UUID]];
		if ([self isPersistentRoot] ||
			[self isBranch])
		{
			if ([[tableColumn identifier] isEqualToString: @"action"])
			{
				NSButtonCell *cell = [[[NSButtonCell alloc] init] autorelease];
				[cell setBezelStyle: NSRoundRectBezelStyle];
				[cell setTitle: @"Open"];
				[cell setTarget: self];
				[cell setAction: @selector(openPersistentRoot:)];
				return cell;				
			}
			else if ([[tableColumn identifier] isEqualToString: @"currentbranch"])
			{
				if ([self isPersistentRoot])
				{
					NSPopUpButtonCell *cell = [[[NSPopUpButtonCell alloc] init] autorelease];
					[cell setBezelStyle: NSRoundRectBezelStyle];
					NSMenu *aMenu = [[[NSMenu alloc] init] autorelease];
					
					NSArray *branches = [self orderedBranchesForUUID: [self UUID]];
					for (ETUUID *aBranch in branches)
					{
						[aMenu addItemWithTitle: [aBranch stringValue]
										 action: nil
								  keyEquivalent: @""];
					}
					
					[cell setEnabled: ([branches count] > 1)];
					[cell setMenu: aMenu];
					
					return cell;
				}
			}
		}
	}
	
	return [tableColumn dataCell];
}

/** @taskunit open button */

- (void)openPersistentRoot: (id)sender
{
	[[NSApp delegate] browsePersistentRootAtPath: [[ctx path] pathByAppendingPathComponent: [self UUID]]];
}

- (void) deleteRow
{	
	if (isPrimitiveInContainer)
	{
		COMutableItem *storeItem = [ctx _storeItemForUUID: UUID];
		id container = [[storeItem valueForAttribute: [self attribute]] mutableCopy];
		id valueToDelete = [[storeItem allObjectsForAttribute: attribute] objectAtIndex: index]; // FIXME: hack
		NSLog(@"Deleting %@ from multivalue", valueToDelete);
		[container removeObject: valueToDelete];
		[storeItem setValue: container forAttribute: attribute];
		[container release];
		
		[ctx _insertOrUpdateItems: S(storeItem)];
		[ctx commitWithMetadata: nil];
	}
	else if (attribute != nil)
	{
		COMutableItem *storeItem = [ctx _storeItemForUUID: UUID];
		NSLog(@"Deleting primitive attribute %@", attribute);
		
		[storeItem removeValueForAttribute: attribute];
		
		[ctx _insertOrUpdateItems: S(storeItem)];
		[ctx commitWithMetadata: nil];
	}
	else // embedded item
	{
		NSLog(@"Deleting embedded item %@", [self UUID]);
		
		COMutableItem *parentItem = [ctx _storeItemForUUID: [parent UUID]];
		
		COType *parentType = [parentItem typeForAttribute: [parent attribute]];
		
		assert([[parentType primitiveType] isEqual: [COType embeddedItemType]]);
		assert([parent attribute] != nil);
	
		if ([[parentItem typeForAttribute: [parent attribute]] isPrimitive])
		{
			assert(0); // FIXME: embedded items in primitive attributes not supported by outline code yet?
		}
		else
		{
			id container = [[parentItem valueForAttribute: [parent attribute]] mutableCopy];
			assert([container containsObject: [self UUID]]);
			NSLog(@"Deleting embedded item %@ from multivalue %@. parent UUID: %@, attrib: %@", 
				[self UUID], container, [parent UUID], [parent attribute]);			
			[container removeObject:  [self UUID]];
			[parentItem setValue: container forAttribute: [parent attribute]];
			[container release];
		}
		
		[ctx _insertOrUpdateItems: S(parentItem)];
		[ctx commitWithMetadata: nil];
	}
	[[NSApp delegate] reloadAllBrowsers];
}

- (id)identifier
{
	ETUUID *aUUID = [self UUID];
	NSString *attr = [self attribute];
	NSNumber *isPrimitiveInContainerObj = [NSNumber numberWithBool: [self isPrimitiveInContainer]];
	
	if (attr == nil) attr = @"";
	
	return S(aUUID, attr, isPrimitiveInContainerObj);
}

/**
 * Sorts rows in an aribtrary but stable order based on UUID
 */
- (NSComparisonResult) compare: (id)anObject
{
	if ([anObject isKindOfClass: [self class]])
	{
		NSComparisonResult result = [[self UUID] compare: [anObject UUID]];
		if (result == NSOrderedSame)
		{
			result = [[self attribute] compare: [anObject attribute]];
		}
		return result;
	}
	return NSOrderedAscending;
}

// Menu stuff

- (void) branch: (id)sender
{
	[ctx createBranchOfPersistentRoot: [self UUID]];
	
	[ctx commitWithMetadata: nil];
	[[NSApp delegate] reloadAllBrowsers];
}

- (void) duplicateBranchAsPersistentRoot: (id)sender
{
	// FIXME: We need a reliable way to get the embedded object which 
	// an object is contained within. This is a horrible hack:
	
	// first parent: the multivalued attribute the branch is in
	// second parent: the embedded object the branch is in
	// third parent: the multivalued attribute the embedded object is in
	// fourth parent: the parent embedded object the embedded object is in
	ETUUID *dest = [[[[[self parent] parent] parent] parent] UUID];
	
	NSLog(@"trying to break out branch %@ into %@ as new UUID", [self UUID], dest);
	
	[ctx createAndInsertNewPersistentRootByCopyingBranch: [self UUID]
										  inItemWithUUID: dest];
	
	[ctx commitWithMetadata: nil];
	[[NSApp delegate] reloadAllBrowsers];
}

- (NSArray *)selectedRows
{
	NSMutableArray *result = [NSMutableArray array];
	
	NSOutlineView *outlineView = [windowController outlineView];
	NSIndexSet *selIndexes = [outlineView selectedRowIndexes];
	
	for (NSUInteger i = [selIndexes firstIndex]; i != NSNotFound; i = [selIndexes indexGreaterThanIndex: i])
	{
		[result addObject: [outlineView itemAtRow: i]];
	}
	
	return [NSArray arrayWithArray: result];
}

- (void) diff: (id)sender
{
	NSLog(@"diff %@", [self selectedRows]);
}

- (NSMenu *)menu
{
	NSMenu *menu = [[[NSMenu alloc] initWithTitle: @""] autorelease];
		
	COMutableItem *storeItem = [ctx _storeItemForUUID: [self UUID]];
	
	NSOutlineView *outlineView = [windowController outlineView];
	NSIndexSet *selIndexes = [outlineView selectedRowIndexes];
	
	if ([selIndexes count] > 2)
	{
		NSLog(@"Try selecting just one or two rows");
	}
	else if ([selIndexes count] == 2)
	{	
		EWPersistentRootOutlineRow *row1 = [outlineView itemAtRow: [selIndexes firstIndex]];
		EWPersistentRootOutlineRow *row2 = [outlineView itemAtRow: [selIndexes indexGreaterThanIndex: [selIndexes firstIndex]]];

		if (([row1 isPersistentRoot] || [row1 isBranch])
			 && ([row2 isPersistentRoot] || [row2 isBranch]))
		{
			{
				NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Diff Persistent Roots/Branches" 
															   action: @selector(diff:) 
														keyEquivalent: @""] autorelease];
				[item setTarget: self];
				[menu addItem: item];
			}
		}
	}
	else
	{
		// Single selection
		
		if ([[storeItem valueForAttribute: @"type"] isEqualToString: @"persistentRoot"])
		{
			NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Create Branch" 
														   action: @selector(branch:) 
													keyEquivalent: @""] autorelease];
			[item setTarget: self];
			[menu addItem: item];
		}
		
		if ([[storeItem valueForAttribute: @"type"] isEqualToString: @"branch"])
		{
			NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Duplicate Branch as Persistent Root" 
														   action: @selector(duplicateBranchAsPersistentRoot:) 
													keyEquivalent: @""] autorelease];
			[item setTarget: self];
			[menu addItem: item];
		}
	}

		
    return menu;
}

@end

