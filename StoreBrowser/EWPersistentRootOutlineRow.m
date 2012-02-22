#import "EWPersistentRootOutlineRow.h"
#import "COMacros.h"
#import "COType+String.h"
#import "EWPersistentRootWindowController.h"
#import "COPath.h"
#import "COSubtree.h"
#import "COSubtreeDiff.h"
#import "COPersistentRootDiff.h"
#import "COSubtreeFactory.h"
#import "COSubtreeFactory+PersistentRoots.h"
#import "COSubtreeCopy.h"
#import "AppDelegate.h"
#import "EWDiffWindowController.h"


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

- (COSubtree *)rowSubtree
{
	return [[ctx persistentRootTree] subtreeWithUUID: UUID];
}

- (BOOL) isPersistentRoot
{
	return [self isEmbeddedObject] && [[COSubtreeFactory factory] isPersistentRoot: [self rowSubtree]];
}
- (BOOL) isBranch
{
	return [self isEmbeddedObject] && [[COSubtreeFactory factory] isBranch: [self rowSubtree]];
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
						itemUUID: [[aContext persistentRootTree] UUID]
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
	
	COSubtree *subtree = [self rowSubtree];
	
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
		COType *type = [subtree typeForAttribute: attribute];
		
		if ([type isPrimitive] &&
			![type isEqual: [COType embeddedItemType]])
		{
			return [NSArray array];
		}
		
		// if it contains embedded objects, just return their UUIDs.
		if ([[type primitiveType] isEqual: [COType embeddedItemType]])
		{
			NSMutableArray *result = [NSMutableArray array];
			
			for (ETUUID *embeddedUUID in [[subtree item] allObjectsForAttribute: attribute])
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

- (COSubtree *)persistentRootOwningBranch
{
	assert([self isBranch]);
	
	COSubtree *proot = [[self rowSubtree] parent];
	assert(proot != nil);
	assert([[COSubtreeFactory factory] isPersistentRoot: proot]);
	
	return proot;
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
			COSubtree *storeItem = [self rowSubtree];
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
			COType *type = [item typeForAttribute: attribute];
			
			if ([type isPrimitive])
			{
				return [item valueForAttribute: attribute];
			}
		}
	}
	else if ([[column identifier] isEqualToString: @"type"])
	{
		COItem *item = [[self rowSubtree] item];
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
			
			NSArray *branches = [self orderedBranchesForSubtree: [self rowSubtree]];
			
			COSubtree *current = [[COSubtreeFactory factory] currentBranchOfPersistentRoot: [self rowSubtree]];
			
			NSUInteger i = [branches indexOfObject: current];
			assert(i < [branches count]);
			
			return [NSNumber numberWithUnsignedInteger: i];
		}
		return nil;
	}
	
	return nil;
}

- (NSImage *)image
{
	if ([self isEmbeddedObject])
	{		
		if ([self isPersistentRoot])
		{
			return [NSImage imageNamed: @"package"]; // persistent root embedded object
		}
		else if	([self isBranch])
		{
			COSubtree *persistentRoot = [self persistentRootOwningBranch];
			if ([[[COSubtreeFactory factory] currentBranchOfPersistentRoot: persistentRoot] isEqual: [self rowSubtree]])
			{
				return [NSImage imageNamed: @"arrow_branch_purple"]; // branch embedded object			
			}
			return [NSImage imageNamed: @"arrow_branch"]; // branch embedded object
		}
		return [NSImage imageNamed: @"brick"]; // regular embedded object
	}
	else
	{
		COType *type = [[self rowSubtree] typeForAttribute: attribute];
		
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

+ (NSComparisonResult) compareUUID: (ETUUID*)uuid1 withUUID: (ETUUID *)uuid2
{
	int diff = memcmp([uuid1 UUIDValue], [uuid2 UUIDValue], 16);
	
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

/**
 * Returns branches for given persistent root in an arbitrary
 * but stable sorted order
 */
- (NSArray *) orderedBranchesForSubtree: (COSubtree*)aPersistentRoot
{
	return [[[[COSubtreeFactory factory] branchesOfPersistentRoot: aPersistentRoot] allObjects] sortedArrayUsingFunction: subtreeSort
																											  context: NULL];
}

- (void) setValue: (id)object forTableColumn: (NSTableColumn *)tableColumn
{
	NSLog(@"Set to %@ col %@", object, [tableColumn identifier]);
	
	if ([[tableColumn identifier] isEqualToString: @"currentbranch"])
	{
		COSubtree *selectedBranch = [[self orderedBranchesForSubtree: [self rowSubtree]] objectAtIndex: [object integerValue]];
		[[COSubtreeFactory factory] setCurrentBranch: selectedBranch
								forPersistentRoot: [self rowSubtree]];
		[ctx commitWithMetadata: nil];
		
		[[NSApp delegate] reloadAllBrowsers];
	}
	if ([[tableColumn identifier] isEqualToString: @"name"])
	{
		if ([self attribute] != nil)
		{
			// Store the old value under a new name
			
			COSubtree *storeItem = [self rowSubtree];
			COType *type = [storeItem typeForAttribute: [self attribute]];
			id value = [storeItem valueForAttribute: [self attribute]];
			
			[storeItem removeValueForAttribute: [self attribute]];			
			[storeItem setValue: value
				   forAttribute: object
						   type: type];
			
			[ctx commitWithMetadata: nil];
			[[NSApp delegate] reloadAllBrowsers];			
		}
	}
	if ([[tableColumn identifier] isEqualToString: @"value"])
	{
		if ([self attribute] != nil)
		{
			NSLog(@"Attempting to store new value '%@' for attribute '%@' of %@",
				  object, [self attribute], [self UUID]);
			
			COSubtree *storeItem = [self rowSubtree];
			
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
			
			[storeItem setPrimitiveValue: value
							forAttribute: [self attribute]
									type: type];

			[ctx commitWithMetadata: nil];
			
			[[NSApp delegate] reloadAllBrowsers];
		}
	}	
}

- (NSCell *)dataCellForTableColumn: (NSTableColumn *)tableColumn
{
	if ([self attribute] == nil) // only if we click on the root of an embedded object
	{
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
					
					NSArray *branches = [self orderedBranchesForSubtree: [self rowSubtree]];
					for (COSubtree *aBranch in branches)
					{
						[aMenu addItemWithTitle: [[aBranch UUID] stringValue]
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
	COSubtree *storeItem = [self rowSubtree];
	
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
		

		[ctx commitWithMetadata: nil];
	}
	else if (attribute != nil)
	{

		NSLog(@"Deleting primitive attribute %@", attribute);
		
		[storeItem removeValueForAttribute: attribute];
		
		[ctx commitWithMetadata: nil];
	}
	else // embedded item
	{
		NSLog(@"Deleting embedded item %@", [self UUID]);
		
		[[ctx persistentRootTree] removeSubtreeWithUUID: [[self rowSubtree] UUID]];
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

- (void) branch: (id)sender
{
	COSubtree *newBranch = [[COSubtreeFactory factory] createBranchOfPersistentRoot: [self rowSubtree]];
	
	EWPersistentRootWindowController *controller = windowController; // FIXME: ugly hack
	
	[ctx commitWithMetadata: nil];
	[[NSApp delegate] reloadAllBrowsers]; // FIXME: ugly.. deallocates self...
	
	[controller orderFrontAndHighlightItem: [newBranch UUID]];
}

- (void) duplicateBranchAsPersistentRoot: (id)sender
{
	COSubtree *newRoot = [[COSubtreeFactory factory] persistentRootByCopyingBranch: [self rowSubtree]];
	COSubtree *dest = [[[self rowSubtree] parent] parent];
	
	NSLog(@"trying to break out branch %@ into %@ as new UUID", [self UUID], dest);
	
	assert(dest != nil);
	
	[dest addTree: newRoot];
	
	EWPersistentRootWindowController *controller = windowController; // FIXME: ugly hack
	
	[ctx commitWithMetadata: nil];
	[[NSApp delegate] reloadAllBrowsers]; // FIXME: ugly.. deallocates self...
	
	[controller orderFrontAndHighlightItem: [newRoot UUID]];
}

- (void) duplicatePersistentRoot: (id)sender
{
	COSubtree *newRoot = [[[self rowSubtree] subtreeCopyRenamingAllItems] subtree];
	COSubtree *dest = [[self rowSubtree] parent];
	
	[newRoot setPrimitiveValue: [NSString stringWithFormat: @"Copy of %@", [newRoot valueForAttribute: @"name"]]
				  forAttribute: @"name"
						  type: [COType stringType]];
	
	[dest addTree: newRoot];
	
	EWPersistentRootWindowController *controller = windowController; // FIXME: ugly hack
	
	[ctx commitWithMetadata: nil];
	[[NSApp delegate] reloadAllBrowsers]; // FIXME: ugly.. deallocates self...
	
	[controller orderFrontAndHighlightItem: [newRoot UUID]];
}

- (void) diff: (id)sender
{
	NSArray *selectedRows = [windowController selectedRows];
	assert([selectedRows count] == 2);

	EWPersistentRootOutlineRow *row1 = [selectedRows objectAtIndex: 0];
	EWPersistentRootOutlineRow *row2 = [selectedRows objectAtIndex: 1];
	
	/*COPersistentRootEditingContext *row1ctx = 
		[COPersistentRootEditingContext editingContextForEditingPath: [[ctx path] pathByAppendingPathComponent: [row1 UUID]]
															 inStore: [ctx store]];

	COPersistentRootEditingContext *row2ctx = 	
		[COPersistentRootEditingContext editingContextForEditingPath: [[ctx path] pathByAppendingPathComponent: [row2 UUID]]
															 inStore: [ctx store]];
	
	assert(row1ctx != nil);
	assert(row2ctx != nil);
	
	COSubtreeDiff *treediff = [COSubtreeDiff diffSubtree: [row1ctx persistentRootTree]
											 withSubtree: [row2ctx persistentRootTree]];
	 
	 */
	
	COPersistentRootDiff *diff = [[COPersistentRootDiff alloc]
									initWithPath: [[ctx path] pathByAppendingPathComponent: [row1 UUID]]
										andPath: [[ctx path] pathByAppendingPathComponent: [row2 UUID]]
										inStore: [ctx store]];
	// FIXME:
	
	EWDiffWindowController *diffWindow = [[EWDiffWindowController alloc] initWithPersistentRootDiff: diff];
	[diffWindow showWindow: nil];
}


- (void) delete: (id)sender
{
	[windowController deleteForward: sender];
}

- (void) switchBranch: (id)sender
{
	[[COSubtreeFactory factory] setCurrentBranch: [self rowSubtree]
							forPersistentRoot: [self persistentRootOwningBranch]];
	[ctx commitWithMetadata: nil];
	
	[[NSApp delegate] reloadAllBrowsers]; // FIXME: ugly.. deallocates self...
}

- (void) addStringKeyValue: (id)sender
{
	COSubtree *subtree = [self rowSubtree];
	[subtree setValue: @"new value" forAttribute: @"newAttribute" type: [COType stringType]];

	[ctx commitWithMetadata: nil];
	
	[[NSApp delegate] reloadAllBrowsers]; // FIXME: ugly.. deallocates self...
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    SEL theAction = [anItem action];
	
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
	else if (theAction == @selector(duplicatePersistentRoot:))
	{
        return [selIndexes count] == 1 && [self isPersistentRoot];
	}
	else if (theAction == @selector(openPersistentRoot:))
	{
		return [selIndexes count] == 1 && ([self isBranch] || [self isPersistentRoot]);
	}
	else if (theAction == @selector(switchBranch:))
	{
        if ([selIndexes count] == 1 && [self isBranch])
		{
			// Only enable the menu item if it is for a different branch than the current one
			return ![[[COSubtreeFactory factory] currentBranchOfPersistentRoot: [self persistentRootOwningBranch]]
						isEqual: [self rowSubtree]];
		}
		return NO;
	}
	else if (theAction == @selector(addStringKeyValue:))
	{
        return ([selIndexes count] == 1 && [self isEmbeddedObject]);
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
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Duplicate Persistent Root" 
													   action: @selector(duplicatePersistentRoot:) 
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

	{
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Add String Key/Value" 
													   action: @selector(addStringKeyValue:) 
												keyEquivalent: @""] autorelease];
		[item setTarget: self];
		[menu addItem: item];
	}	
	
    return menu;
}

@end

