#import "EWPersistentRootWindowController.h"
#import "COMacros.h"
#import <AppKit/NSOutlineView.h>
#import "EWGraphRenderer.h"

@implementation EWPersistentRootWindowController

- (void) setupCtx
{
	ASSIGN(ctx, [COPersistentRootEditingContext	editingContextForEditingPath: path
																	 inStore: store]);
	assert(ctx != nil);
	
	DESTROY(outlineModel);
	outlineModel = [[EWPersistentRootOutlineRow alloc] initWithContext: ctx
																parent: nil];
}

- (id)initWithPath: (COPath*)aPath
			 store: (COStore*)aStore
{
	self = [super initWithWindowNibName: @"PersistentRootWindow"];
	
	ASSIGN(path, aPath);
	ASSIGN(store, aStore);

	[self setupCtx];
	
	NSLog(@"%@, %@", [self window], [aStore URL]);
	
	return self;
}

- (NSString *)persistentRootTitle
{
	if ([path isEmpty])
	{
		return @"Store Root";
	}
	else
	{
		COPersistentRootEditingContext *parentCtx = [COPersistentRootEditingContext editingContextForEditingPath: [path pathByDeletingLastPathComponent] 
																										 inStore: store];
		BOOL isBranch = [parentCtx isBranch: [path lastPathComponent]];
		
		if (isBranch)
		{
			return [@"Branch " stringByAppendingString: [path stringValue]];	
		}
		else
		{
			return [@"Persistent Root " stringByAppendingString: [path stringValue]];
		}
	}
}

- (void)windowDidLoad
{
	[outlineView setTarget: self];
	[outlineView setDoubleAction: @selector(doubleClick:)];
	
	{
		NSBrowserCell *cell = [[[NSBrowserCell alloc] init] autorelease];
	
		[[outlineView tableColumnWithIdentifier: @"name"] setDataCell: cell];
	}
	
	if ([path isEmpty])
	{
		[highlightInParentButton setEnabled: NO];
		[undoButton setEnabled: NO];
		[redoButton setEnabled: NO];
	}
	else
	{
		EWGraphRenderer *renderer = [[EWGraphRenderer alloc] init];
		[renderer layoutGraphOfStore: store];
		[historyView setGraphRenderer: renderer];
		[renderer release];
	}
	
	[[self window] setTitle: [self persistentRootTitle]];
	
	
}

- (void) reloadBrowser
{
	[self setupCtx];
	[outlineView reloadData];
}

- (IBAction) highlightInParent: (id)sender
{
	assert(![path isEmpty]);
	
	[[[NSApp delegate] windowControllerForPath: [path pathByDeletingLastPathComponent]] 
		orderFrontAndHighlightItem: [path lastPathComponent]];
}

- (IBAction) undo: (id)sender
{
	COPersistentRootEditingContext *parentCtx = [COPersistentRootEditingContext editingContextForEditingPath: [path pathByDeletingLastPathComponent] 
														 inStore: store];
	
	[parentCtx undo: [path lastPathComponent]];
	[parentCtx commitWithMetadata: nil];
	[[NSApp delegate] reloadAllBrowsers];
}

- (IBAction) redo: (id)sender
{
	COPersistentRootEditingContext *parentCtx = [COPersistentRootEditingContext editingContextForEditingPath: [path pathByDeletingLastPathComponent] 
																									 inStore: store];	
	[parentCtx redo: [path lastPathComponent]];
	[parentCtx commitWithMetadata: nil];
	[[NSApp delegate] reloadAllBrowsers];
}

static EWPersistentRootOutlineRow *searchForUUID(EWPersistentRootOutlineRow *start, ETUUID *aUUID)
{
	if ([[start UUID] isEqual: aUUID] && [start attribute] == nil)
	{
		return start;
	}
	else
	{
		for (EWPersistentRootOutlineRow *row in [start children])
		{
			EWPersistentRootOutlineRow *result = searchForUUID(row, aUUID);
			if (result != nil)
			{
				return result;
			}
		}
		return nil;
	}
}

static void expandParentsOfItem(NSOutlineView *aView, EWPersistentRootOutlineRow *item)
{
	NSMutableArray *anArray = [NSMutableArray array];
	
	for (EWPersistentRootOutlineRow *parent = [item parent]; 
		 parent != nil;
		 parent = [parent parent])
	{
		[anArray addObject: parent];
	}
		 
	for (id row in [anArray reverseObjectEnumerator])
	{
		NSLog(@"expand %p", row);
		[aView expandItem: row];
	}	
}

- (void) orderFrontAndHighlightItem: (ETUUID*)aUUID
{
	[self showWindow: nil];	
	
	EWPersistentRootOutlineRow *row = searchForUUID(outlineModel, aUUID);
	assert(row != nil);

	/*
	NSLog(@"%d items", (int)[outlineView numberOfRows]);
	
	NSLog(@"item 0: %p", [outlineView itemAtRow: 0]);	
	NSLog(@"outlineModel: %p", outlineModel);	
	NSLog(@"outlineModel first child: %p", [[outlineModel children] objectAtIndex: 0]);	
	*/
	
	expandParentsOfItem(outlineView, row);
	
	[outlineView selectRowIndexes: [NSIndexSet indexSetWithIndex: [outlineView rowForItem: row]]
			 byExtendingSelection: NO];
}

/* convenience */

- (EWPersistentRootOutlineRow *)modelForItem: (id)anItem
{
	EWPersistentRootOutlineRow *model = anItem;
	if (model == nil)
	{
		model = outlineModel;
	}
	return model;
}

- (EWPersistentRootOutlineRow *) selectedItem
{
	return [self modelForItem:
				[outlineView itemAtRow: [outlineView selectedRow]]];
}

/**
 * Returns branches for given persistent root in an arbitrary
 * but stable sorted order
 */
- (NSArray *) orderedBranchesForUUID: (ETUUID*)aPersistentRoot
{
	return [[[ctx branchesOfPersistentRoot: aPersistentRoot] allObjects] sortedArrayUsingSelector: @selector(compare:)];
}

/* NSOutlineView Target/Action */

- (void)doubleClick: (id)sender
{
	if (sender == outlineView)
	{
		EWPersistentRootOutlineRow *row = [self selectedItem];
		
		NSLog(@"Double click %@", [row UUID]);
		
		if ([row attribute] == nil) // only if we click on the root of an embedded object
		{
			COStoreItem *item = [ctx _storeItemForUUID: [row UUID]];
			if ([[item valueForAttribute: @"type"] isEqualToString: @"persistentRoot"] ||
				[[item valueForAttribute: @"type"] isEqualToString: @"branch"])
			{
				[[NSApp delegate] browsePersistentRootAtPath: [path pathByAppendingPathComponent: [row UUID]]];
			}
		}
		
		// FIXME:
		// setting a double action on an outline view seems to break normal editing
		// so we hack it in here.
	}
}


/* NSOutlineView data source */

- (NSInteger) outlineView: (NSOutlineView *)outlineView numberOfChildrenOfItem: (id)item
{
	return [[[self modelForItem: item] children] count];
}

- (id) outlineView: (NSOutlineView *)outlineView child: (NSInteger)index ofItem: (id)item
{
	return [[[self modelForItem: item] children] objectAtIndex: index];
}

- (BOOL) outlineView: (NSOutlineView *)outlineView isItemExpandable: (id)item
{
	return [self outlineView: outlineView numberOfChildrenOfItem: item] > 0;
}

- (id) outlineView: (NSOutlineView *)outlineView objectValueForTableColumn: (NSTableColumn *)column byItem: (id)item
{
	if ([[column identifier] isEqualToString: @"currentbranch"])
	{
		COStoreItem *storeItem = [ctx _storeItemForUUID: [item UUID]];
		if ([[storeItem valueForAttribute: @"type"] isEqualToString: @"persistentRoot"]
			&& [item attribute] == nil) // FIXME: horrible hack
		{
			
			// NSPopupButtonCell takes a NSNumber indicating the index in the menu.
			
			NSArray *branches = [self orderedBranchesForUUID: [item UUID]];

			ETUUID *current = [ctx currentBranchOfPersistentRoot: [item UUID]];
			
			NSUInteger i = [branches indexOfObject: current];
			assert(i < [branches count]);
			
			return [NSNumber numberWithInt: i];
		}
		return nil;
	}
	return [[self modelForItem: item] valueForTableColumn: column];
}

/* NSOutlineView delegate */

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([[tableColumn identifier] isEqualToString: @"name"])
	{
		if ([cell isKindOfClass: [NSBrowserCell class]])
		{
			[cell setLeaf: YES];
			[cell setImage: [item image]];
		}
	}
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([item attribute] == nil) // only if we click on the root of an embedded object
	{
		COStoreItem *storeItem = [ctx _storeItemForUUID: [item UUID]];
		if ([[storeItem valueForAttribute: @"type"] isEqualToString: @"persistentRoot"] ||
			[[storeItem valueForAttribute: @"type"] isEqualToString: @"branch"])
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
				if ([[storeItem valueForAttribute: @"type"] isEqualToString: @"persistentRoot"])
				{
					NSPopUpButtonCell *cell = [[[NSPopUpButtonCell alloc] init] autorelease];
					[cell setBezelStyle: NSRoundRectBezelStyle];
					NSMenu *aMenu = [[[NSMenu alloc] init] autorelease];
					
					for (ETUUID *aBranch in [self orderedBranchesForUUID: [item UUID]])
					{
						[aMenu addItemWithTitle: [aBranch stringValue]
										 action: nil
								  keyEquivalent: @""];
					}
					[cell setMenu: aMenu];
					
					return cell;
				}
			}
		}
	}
		
	return [tableColumn dataCell];
}

- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{
	NSLog(@"Set to %@ col %@", object, [tableColumn identifier]);
	
	if ([[tableColumn identifier] isEqualToString: @"currentbranch"])
	{
		ETUUID *selectedBranch = [[self orderedBranchesForUUID: [item UUID]] objectAtIndex: [object integerValue]];
		[ctx setCurrentBranch: selectedBranch
			forPersistentRoot: [item UUID]];
		[ctx commitWithMetadata: nil];
		
		[[NSApp delegate] reloadAllBrowsers];
	}
	if ([[tableColumn identifier] isEqualToString: @"value"])
	{
		if ([item attribute] != nil)
		{
			NSLog(@"Attempting to store new value '%@' for attribute '%@' of %@",
				  object, [item attribute], [item UUID]);
			
			COStoreItem *storeItem = [ctx _storeItemForUUID: [item UUID]];

			// FIXME: won't work for multivalued properties..
			// FIXME: will currently only work for strings..
			
			[storeItem setValue: object
				   forAttribute: [item attribute]];
			[ctx _insertOrUpdateItems: S(storeItem)];
			[ctx commitWithMetadata: nil];
			
			[[NSApp delegate] reloadAllBrowsers];
		}
	}
}

/** @taskunit open button */

- (void)openPersistentRoot: (id)sender
{
	EWPersistentRootOutlineRow *row = [self selectedItem];
	
	[[NSApp delegate] browsePersistentRootAtPath: [path pathByAppendingPathComponent: [row UUID]]];
}


@end
