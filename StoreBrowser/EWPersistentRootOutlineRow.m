#import "EWPersistentRootOutlineRow.h"
#import "EWPersistentRootWindowController.h"
#import "COMacros.h"

@implementation EWPersistentRootOutlineRow

- (EWPersistentRootOutlineRow *) parent
{
	return parent;
}

- (id) initWithContext: (COObjectGraphContext *)aContext
			  itemUUID: (COUUID *)aUUID
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

- (COObject *)rowSubtree
{
	return [ctx objectForUUID: UUID];
}

- (BOOL) isEmbeddedObject
{
	return attribute == nil;
}

- (id) initWithContext: (COObjectGraphContext *)aContext
			  itemUUID: (COUUID *)aUUID
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

- (id) initWithContext: (COObjectGraphContext *)aContext
			  itemUUID: (COUUID *)aUUID
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

- (id)initWithContext: (COObjectGraphContext *)aContext
			   parent: (EWPersistentRootOutlineRow *)aParent
	 windowController: (EWPersistentRootWindowController *)aController
{
	return [self initWithContext: aContext
						itemUUID: [[aContext rootObject] UUID]
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

- (COUUID *)UUID
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
	
	COObject *subtree = [self rowSubtree];
	
	if ([self isEmbeddedObject]) // no attribute, so a root node for a persistent root
	{
		// return all attribute names, sorted alphabetically
		
		NSMutableArray *result = [NSMutableArray array];
		
		for (NSString *attr in [subtree attributeNames])
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
		COType type = [subtree typeForAttribute: attribute];
		
		if (COTypeIsPrimitive(type) &&
			![type isEqual: kCOEmbeddedItemType])
		{
			return [NSArray array];
		}
		
		// if it contains embedded objects, just return their UUIDs.
		if (COPrimitiveType(type) == kCOEmbeddedItemType)
		{
			NSMutableArray *result = [NSMutableArray array];
			
			for (COUUID *embeddedUUID in [[subtree item] allObjectsForAttribute: attribute])
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
			
			const NSUInteger count = [[[subtree item] allObjectsForAttribute: attribute] count];
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
			COItem *storeItem = [[self rowSubtree] item];
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
			COObject *storeItem = [self rowSubtree];
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
			COItem *item = [[self rowSubtree] item];
			COType type = [item typeForAttribute: attribute];
			
			if (COTypeIsPrimitive(type))
			{
				return [item valueForAttribute: attribute];
			}
		}
	}
	else if ([[column identifier] isEqualToString: @"type"])
	{
		COItem *item = [[self rowSubtree] item];
		COType type = [item typeForAttribute: attribute];

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
			return [kCOEmbeddedItemType description];
		}
	}
	
	return nil;
}

- (NSImage *)image
{
	if ([self isEmbeddedObject])
	{		
		return [NSImage imageNamed: @"brick"]; // regular embedded object
	}
	else
	{
		COType type = [[self rowSubtree] typeForAttribute: attribute];
		
		if (COTypeIsPrimitive(type))
		{
			return [NSImage imageNamed: @"bullet_yellow"]; // primitive attribute
		}
		else
		{
			return [NSImage imageNamed: @"bullet_yellow_multiple"]; // multivalued attribute
		}
	}
}

+ (NSComparisonResult) compareUUID: (COUUID*)uuid1 withUUID: (COUUID *)uuid2
{
	int diff = memcmp([uuid1 bytes], [uuid2 bytes], 16);
	
    if (diff < 0)
	{
        return NSOrderedAscending;
	}
    else if (diff > 0)
	{
        return NSOrderedDescending;
	}
    else
	{
        return NSOrderedSame;
	}
}

static NSInteger subtreeSort(id subtree1, id subtree2, void *context)
{
	return [EWPersistentRootOutlineRow compareUUID: [subtree1 UUID] withUUID: [subtree2 UUID]];	
}

- (void) setValue: (id)object forTableColumn: (NSTableColumn *)tableColumn
{
	NSLog(@"Set to %@ col %@", object, [tableColumn identifier]);
	
	if ([[tableColumn identifier] isEqualToString: @"name"])
	{
		if ([self attribute] != nil)
		{
			// Store the old value under a new name
			
			COObject *storeItem = [self rowSubtree];
			COType type = [storeItem typeForAttribute: [self attribute]];
			id value = [storeItem valueForAttribute: [self attribute]];
			
			[storeItem removeValueForAttribute: [self attribute]];			
			[storeItem setValue: value
				   forAttribute: object
						   type: type];
			
			[self commitWithMetadata: nil];
		}
	}
	if ([[tableColumn identifier] isEqualToString: @"value"])
	{
		if ([self attribute] != nil)
		{
			NSLog(@"Attempting to store new value '%@' for attribute '%@' of %@",
				  object, [self attribute], [self UUID]);
			
			COObject *storeItem = [self rowSubtree];
			
			COType type = [storeItem typeForAttribute: [self attribute]];
			
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
			
			id value = [type valueForStringValue: object]; // e.g. converts string -> COUUID
			
			[storeItem setValue: value
                    forAttribute: [self attribute]
                            type: type];

            [self commitWithMetadata: nil];
		}
	}	
}

- (NSCell *)dataCellForTableColumn: (NSTableColumn *)tableColumn
{
	return [tableColumn dataCell];
}

- (void) deleteRow
{	
	COObject *storeItem = [self rowSubtree];
	
	if (isPrimitiveInContainer)
	{
		// FIXME:
		assert(0);
		 
		//id container = [[storeItem valueForAttribute: [self attribute]] mutableCopy];
		//id valueToDelete = [[storeItem allObjectsForAttribute: attribute] objectAtIndex: index]; // FIXME: hack
		//NSLog(@"Deleting %@ from multivalue", valueToDelete);
		//[container removeObject: valueToDelete];
		//[storeItem setValue: container forAttribute: attribute];
		//[container release];
		

		[self commitWithMetadata: nil];
	}
	else if (attribute != nil)
	{

		NSLog(@"Deleting primitive attribute %@", attribute);
		
		[storeItem removeValueForAttribute: attribute];
		
		[self commitWithMetadata: nil];
	}
	else // embedded item
	{
		NSLog(@"Deleting embedded item %@", [self UUID]);
		
        COUUID *uuid = [[self rowSubtree] UUID];
        
        [[[ctx objectForUUID: uuid] parentObject] removeDescendentObject: uuid];

		[self commitWithMetadata: nil];
	}
}

- (id)identifier
{
	COUUID *aUUID = [self UUID];
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
		NSComparisonResult result = [EWPersistentRootOutlineRow compareUUID: [self UUID] withUUID: [anObject UUID]];
		if (result == NSOrderedSame)
		{
			result = [[self attribute] compare: [anObject attribute]];
		}
		return result;
	}
	return NSOrderedAscending;
}

// Menu stuff

- (void) duplicateEmbeddedItem: (id)sender
{
    assert(0);
    
//	COObject *newRoot = [[[self rowSubtree]  subtreeCopyRenamingAllItems] subtree];
//	COObject *dest = [[self rowSubtree] parent];
//	
//	if ([newRoot valueForAttribute: @"name"] != nil)
//	{
//		[newRoot setPrimitiveValue: [NSString stringWithFormat: @"Copy of %@", [newRoot valueForAttribute: @"name"]]
//					  forAttribute: @"name"
//							  type: kCOStringType];
//	}	
//	[dest addTree: newRoot];
//	
//	EWPersistentRootWindowController *controller = windowController; // FIXME: ugly hack
//	
//	[self commitWithMetadata: nil];
//	[windowController reloadBrowser]; // FIXME: ugly.. deallocates self...
//	
//	[controller orderFrontAndHighlightItem: [newRoot UUID]];
}

- (void) diffEmbeddedItems: (id)sender
{
	NSArray *selectedRows = [windowController selectedRows];
	assert([selectedRows count] == 2);
	
	EWPersistentRootOutlineRow *row1 = [selectedRows objectAtIndex: 0];
	EWPersistentRootOutlineRow *row2 = [selectedRows objectAtIndex: 1];
	
//	COSubtreeDiff *diff = [COSubtreeDiff diffSubtree: [row1 rowSubtree]
//										 withSubtree: [row2 rowSubtree]
//									sourceIdentifier: @"fixme"];
	// FIXME:
	
//	NSLog(@"Embedded item diff: %@", diff);
}

- (void) delete: (id)sender
{
	[windowController deleteForward: sender];
}

- (COObject *) itemWithLabel: (NSString *)label
{
	COObjectGraphContext *ctx = [[[COObjectGraphContext alloc] init] autorelease];
    [[ctx rootObject] setValue: label
                  forAttribute: @"label"
                          type: kCOStringType];
    return [ctx rootObject];
}


- (void) addStringKeyValue: (id)sender
{
	COObject *subtree = [self rowSubtree];
	[subtree setValue: @"new value" forAttribute: @"newAttribute" type: kCOStringType];

	[self commitWithMetadata: nil];
}

- (void) addEmbeddedItem: (id)sender
{
	COObject *subtree = [self rowSubtree];
	COObject *newItem = [self itemWithLabel: @"new item"];
	[subtree addObjectToContents: newItem];

	[self commitWithMetadata: nil];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    SEL theAction = [anItem action];
	
	NSOutlineView *outlineView = [windowController outlineView];
	NSIndexSet *selIndexes = [outlineView selectedRowIndexes];
	
    if (theAction == @selector(duplicateEmbeddedItem:))
	{
        return [selIndexes count] == 1 && [self isEmbeddedObject];
	}
    else if (theAction == @selector(diffEmbeddedItems:))
	{
        if ([selIndexes count] == 2)
		{	
			EWPersistentRootOutlineRow *row1 = [outlineView itemAtRow: [selIndexes firstIndex]];
			EWPersistentRootOutlineRow *row2 = [outlineView itemAtRow: [selIndexes indexGreaterThanIndex: [selIndexes firstIndex]]];
			
			return [row1 isEmbeddedObject] && [row2 isEmbeddedObject];
		}
		return NO;
	}
	else if (theAction == @selector(addStringKeyValue:))
	{
        return ([selIndexes count] == 1 && [self isEmbeddedObject]);
	}
    else if (theAction == @selector(addEmbeddedItem:)
              || theAction == @selector(addPersistentRoot:))
	{
        return ([selIndexes count] == 1);
	}
	
	return [self respondsToSelector: theAction];
}


- (NSMenu *)menu
{
	NSMenu *menu = [[[NSMenu alloc] initWithTitle: @""] autorelease];

	[menu addItemWithTitle:@"Cut" action: @selector(cut:) keyEquivalent:@""];
	[menu addItemWithTitle:@"Copy" action: @selector(copy:) keyEquivalent:@""];
	[menu addItemWithTitle:@"Paste" action: @selector(paste:) keyEquivalent:@""];
	
	{
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Duplicate" 
													   action: @selector(duplicateEmbeddedItem:) 
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
	
	[menu addItem: [NSMenuItem separatorItem]];

	{
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Diff Pair of Embedded Items" 
													   action: @selector(diffEmbeddedItems:) 
												keyEquivalent: @""] autorelease];
		[item setTarget: self];
		[menu addItem: item];
	}	
	
	[menu addItem: [NSMenuItem separatorItem]];

	{
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Add String Key/Value" 
													   action: @selector(addStringKeyValue:) 
												keyEquivalent: @""] autorelease];
		[item setTarget: self];
		[menu addItem: item];
	}	

	{
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Add Embedded Item" 
													   action: @selector(addEmbeddedItem:) 
												keyEquivalent: @""] autorelease];
		[item setTarget: self];
		[menu addItem: item];
	}	
	
    return menu;
}

- (void) commitWithMetadata: (NSDictionary*)meta
{
    [windowController reloadBrowser];
    
}
@end

