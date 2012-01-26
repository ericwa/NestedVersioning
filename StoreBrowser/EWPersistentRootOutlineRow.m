#import "EWPersistentRootOutlineRow.h"
#import "COMacros.h"
#import "COType+String.h"
#import "EWPersistentRootWindowController.h"
#import "COPath.h"
#import "COTreeDiff.h"

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
	return [self isEmbeddedObject] && [ctx isPersistentRoot: UUID];
}
- (BOOL) isBranch
{
	return [self isEmbeddedObject] && [ctx isBranch: UUID];
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
			ETUUID *persistentRoot = [[[self parent] parent] UUID]; // FIXME: hack
			if ([[ctx currentBranchOfPersistentRoot: persistentRoot] isEqual: [self UUID]])
			{
				return [NSImage imageNamed: @"arrow_branch_purple"]; // branch embedded object			
			}
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
			return [NSImage imageNamed: @"bullet_yellow_multiple"]; // multivalued attribute
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
	ETUUID *newBranch = [ctx createBranchOfPersistentRoot: [self UUID]];
	
	EWPersistentRootWindowController *controller = windowController; // FIXME: ugly hack
	
	[ctx commitWithMetadata: nil];
	[[NSApp delegate] reloadAllBrowsers]; // FIXME: ugly.. deallocates self...
	
	[controller orderFrontAndHighlightItem: newBranch];
}

- (void) duplicateBranchAsPersistentRoot: (id)sender
{
	// FIXME: We need a reliable way to get the embedded object which 
	// an object is contained within. This is a horrible hack:
	
	ETUUID *persistentRootOwningBranch = [[[self parent] parent] UUID];
	
	// first parent: the multivalued attribute the branch is in
	// second parent: the embedded object the branch is in
	// third parent: the multivalued attribute the embedded object is in
	// fourth parent: the parent embedded object the embedded object is in
	ETUUID *dest = [[[[[self parent] parent] parent] parent] UUID];
	
	NSLog(@"trying to break out branch %@ into %@ as new UUID", [self UUID], dest);
	
	ETUUID *newRoot = [ctx createAndInsertNewPersistentRootByCopyingBranch: [self UUID]
														  ofPersistentRoot: persistentRootOwningBranch
															inItemWithUUID: dest];
	
	EWPersistentRootWindowController *controller = windowController; // FIXME: ugly hack
	
	[ctx commitWithMetadata: nil];
	[[NSApp delegate] reloadAllBrowsers]; // FIXME: ugly.. deallocates self...
	
	[controller orderFrontAndHighlightItem: newRoot];
}

- (void) diff: (id)sender
{
	NSArray *selectedRows = [windowController selectedRows];
	assert([selectedRows count] == 2);

	EWPersistentRootOutlineRow *row1 = [selectedRows objectAtIndex: 0];
	EWPersistentRootOutlineRow *row2 = [selectedRows objectAtIndex: 1];
	
	COPersistentRootEditingContext *row1ctx = 
		[COPersistentRootEditingContext editingContextForEditingPath: [[ctx path] pathByAppendingPathComponent: [row1 UUID]]
															 inStore: [ctx store]];

	COPersistentRootEditingContext *row2ctx = 	
		[COPersistentRootEditingContext editingContextForEditingPath: [[ctx path] pathByAppendingPathComponent: [row2 UUID]]
															 inStore: [ctx store]];
	
	assert(row1ctx != nil);
	assert(row2ctx != nil);
	
	COTreeDiff *treediff = [COTreeDiff diffRootItem: [row1ctx rootUUID]
									   withRootItem: [row2ctx rootUUID]
									inFaultProvider: row1ctx
								  withFaultProvider: row2ctx];
	NSLog(@"tree diff: %@", treediff);
}


- (void) delete: (id)sender
{
	[windowController deleteForward: sender];
}

- (void) switchBranch: (id)sender
{
	// FIXME: We need a reliable way to get the embedded object which 
	// an object is contained within. This is a horrible hack:
	
	ETUUID *persistentRootOwningBranch = [[[self parent] parent] UUID];
	
	[ctx setCurrentBranch: [self UUID]
		forPersistentRoot: persistentRootOwningBranch];
	[ctx commitWithMetadata: nil];
	
	[[NSApp delegate] reloadAllBrowsers]; // FIXME: ugly.. deallocates self...
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    SEL theAction = [anItem action];

	COMutableItem *storeItem = [ctx _storeItemForUUID: [self UUID]];
	
	NSOutlineView *outlineView = [windowController outlineView];
	NSIndexSet *selIndexes = [outlineView selectedRowIndexes];
	
    if (theAction == @selector(diff:))
    {
        if ([selIndexes count] == 2)
		{	
			EWPersistentRootOutlineRow *row1 = [outlineView itemAtRow: [selIndexes firstIndex]];
			EWPersistentRootOutlineRow *row2 = [outlineView itemAtRow: [selIndexes indexGreaterThanIndex: [selIndexes firstIndex]]];
			
			if (([row1 isPersistentRoot] || [row1 isBranch])
				&& ([row2 isPersistentRoot] || [row2 isBranch]))
			{
				return YES;
			}
		}
		return NO;
    }
	else if (theAction == @selector(branch:))
    {
        return [selIndexes count] == 1 && [self isPersistentRoot];
    }
	else if (theAction == @selector(duplicateBranchAsPersistentRoot:))
	{
        return [selIndexes count] == 1 && [self isBranch];
	}
	else if (theAction == @selector(openPersistentRoot:))
	{
		return [selIndexes count] == 1 && ([self isBranch] || [self isPersistentRoot]);
	}
	else if (theAction == @selector(switchBranch:))
	{
        if ([selIndexes count] == 1 && [self isBranch])
		{
			// FIXME: We need a reliable way to get the embedded object which 
			// an object is contained within. This is a horrible hack:
			
			ETUUID *persistentRootOwningBranch = [[[self parent] parent] UUID];
			
			// Only enable the menu item if it is for a different branch than the current one
			return ![[ctx currentBranchOfPersistentRoot: persistentRootOwningBranch] isEqual: [self UUID]];
		}
		return NO;
	}
	
	return [self respondsToSelector: theAction];
}


- (NSMenu *)menu
{
	NSMenu *menu = [[[NSMenu alloc] initWithTitle: @""] autorelease];

	{
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Open Persistent Roots/Branch Contents" 
													   action: @selector(openPersistentRoot:) 
												keyEquivalent: @""] autorelease];
		[item setTarget: self];
		[menu addItem: item];
	}
	
	{
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Diff Pair of Persistent Roots/Branches" 
													   action: @selector(diff:) 
												keyEquivalent: @""] autorelease];
		[item setTarget: self];
		[menu addItem: item];
	}
	
	{
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Create Branch" 
													   action: @selector(branch:) 
												keyEquivalent: @""] autorelease];
		[item setTarget: self];
		[menu addItem: item];
	}
	
	{
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Switch to Branch" 
													   action: @selector(switchBranch:) 
												keyEquivalent: @""] autorelease];
		[item setTarget: self];
		[menu addItem: item];
	}
	
	{
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Duplicate Branch as Persistent Root" 
													   action: @selector(duplicateBranchAsPersistentRoot:) 
												keyEquivalent: @""] autorelease];
		[item setTarget: self];
		[menu addItem: item];
	}

	{
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Delete" 
													   action: @selector(delete:) 
												keyEquivalent: @""] autorelease];
		[item setTarget: self];
		[menu addItem: item];
	}	
	
    return menu;
}

@end

