#import <Cocoa/Cocoa.h>
#import "EWPersistentRootWindowController.h"
#import "COMacros.h"
#import "EWGraphRenderer.h"
#import "COSubtreeFactory.h"
#import "COSubtreeFactory+PersistentRoots.h"
#import "COSubtreeFactory+Undo.h"
#import "AppDelegate.h"
#import "COType.h"
#import "EWIconTextFieldCell.h"

@implementation EWPersistentRootWindowController

- (void) setupCtx
{
	ASSIGN(ctx, [COPersistentRootEditingContext	editingContextForEditingPath: path
																	 inStore: store]);
	assert(ctx != nil);
	
	DESTROY(outlineModel);
	outlineModel = [[EWPersistentRootOutlineRow alloc] initWithContext: ctx
																parent: nil
													  windowController: self];
	
	// View may not exist yet.
	// FIXME: duplicated code in init...
	if (![path isEmpty])
	{
		EWGraphRenderer *renderer = [[EWGraphRenderer alloc] initWithStore: store];
		[renderer layoutGraph];
		[historyView setGraphRenderer: renderer];
		[renderer release];
		
		[historyView setCurrentCommit: [self currentCommit]];	
	}
	
	NSLog(@"%@", [ctx persistentRootTree]);
}

- (id)initWithPath: (COPath*)aPath
			 store: (COStore*)aStore
{
	self = [super initWithWindowNibName: @"PersistentRootWindow"];
	
	ASSIGN(path, aPath);
	ASSIGN(store, aStore);
	ASSIGN(expansion, [NSMutableDictionary dictionary]);
	
	[self setupCtx];
	
	NSLog(@"%@, %@", [self window], [aStore URL]);
	
	return self;
}

- (COSubtree *)persistentRootItem
{
	if ([path isEmpty])
	{
		return nil;
	}
	else
	{
		COPersistentRootEditingContext *parentCtx = [COPersistentRootEditingContext editingContextForEditingPath: [path pathByDeletingLastPathComponent] 
																										 inStore: store];
		
		COSubtree *persistentRootTree = [parentCtx persistentRootTree];
		COSubtree *item = [persistentRootTree subtreeWithUUID: [path lastPathComponent]];
		return item;
	}
}

- (NSString *)persistentRootTitle
{
	if ([path isEmpty])
	{
		return @"Store Root";
	}
	else
	{
		COSubtree *item = [self persistentRootItem];
		
		NSString *displayName = [[COSubtreeFactory factory] displayNameForBranchOrPersistentRoot: item];
		
		if ([[COSubtreeFactory factory] isBranch: item])
		{
			NSString *persistentRootDisplayName = [[COSubtreeFactory factory] displayNameForBranchOrPersistentRoot: [item parent]];
			
			return [NSString stringWithFormat: @"Branch '%@' of '%@' (%@)", displayName, persistentRootDisplayName, [path stringValue]];	
		}
		else if ([[COSubtreeFactory factory] isPersistentRoot: item])
		{
			return [NSString stringWithFormat: @"Persistent Root '%@' (%@)", displayName,  [path stringValue]];
		}
		else
		{
			assert(0);
		}

	}
}

- (BOOL) canUndo
{
	COSubtree *item = [self persistentRootItem];
	if (nil != item)
	{
		return [[COSubtreeFactory factory] canUndo: item store: store];
	}
	return NO;
}

- (BOOL) canRedo
{
	COSubtree *item = [self persistentRootItem];
	if (nil != item)
	{
		return [[COSubtreeFactory factory] canRedo: item store: store];
	}
	return NO;
}

- (void)windowDidLoad
{
	[outlineView registerForDraggedTypes:
	 [NSArray arrayWithObject: EWDragType]];
	
	[outlineView setTarget: self];
	[outlineView setDoubleAction: @selector(doubleClick:)];
	
	{
		EWIconTextFieldCell *cell = [[[EWIconTextFieldCell alloc] init] autorelease];
		[cell setEditable: YES];
		[[outlineView tableColumnWithIdentifier: @"name"] setDataCell: cell];
	}
	
	[undoButton setEnabled: [self canUndo]];
	[redoButton setEnabled: [self canRedo]];
	
	if ([path isEmpty])
	{
		[highlightInParentButton setEnabled: NO];
		[splitter setPosition: 0.0 ofDividerAtIndex: 0];
	}
	else
	{
		EWGraphRenderer *renderer = [[EWGraphRenderer alloc] initWithStore: store];
		[renderer layoutGraph];
		[historyView setGraphRenderer: renderer];
		[renderer release];
		
		[historyView setCurrentCommit: [self currentCommit]];	
	}
	
	[[self window] setTitle: [self persistentRootTitle]];
}

- (BOOL) isExpanded: (EWPersistentRootOutlineRow*)aRow
{
	return [[expansion objectForKey: [aRow identifier]] boolValue];
}
- (void) setExpanded: (BOOL)flag
			  forRow: (EWPersistentRootOutlineRow *)aRow
{
	[expansion setObject: [NSNumber numberWithBool: flag] forKey: [aRow identifier]];
}

- (void)doExpansion: (EWPersistentRootOutlineRow *)row
{
	if ([self isExpanded: row])
	{
		[outlineView expandItem: row];
	}
	for (EWPersistentRootOutlineRow *child in [row children])
	{
		[self doExpansion: child];
	}
}

- (void) reloadBrowser
{
	[self setupCtx];
	[outlineView reloadData];
	[self doExpansion: outlineModel];
	
	[undoButton setEnabled: [self canUndo]];
	[redoButton setEnabled: [self canRedo]];
}

- (IBAction) highlightInParent: (id)sender
{
	assert(![path isEmpty]);
	
	[[(AppDelegate*)[NSApp delegate] windowControllerForPath: [path pathByDeletingLastPathComponent]] 
		orderFrontAndHighlightItem: [path lastPathComponent]];
}

/**
 * FIXME: This is a bit ugly
 */
- (ETUUID *) currentCommit
{
	if (![path isEmpty])
	{
		COPersistentRootEditingContext *parentCtx = [COPersistentRootEditingContext editingContextForEditingPath: [path pathByDeletingLastPathComponent] 
																										 inStore: store];
		
		COSubtree *item = [[parentCtx persistentRootTree] subtreeWithUUID: [path lastPathComponent]];
		
		ETUUID *currentCommit = [[COSubtreeFactory factory] currentVersionForBranchOrPersistentRoot: item];
		assert(currentCommit != nil);
		
		return currentCommit;
	}
	return nil;
}

- (IBAction) undo: (id)sender
{
	COPersistentRootEditingContext *parentCtx = [COPersistentRootEditingContext editingContextForEditingPath: [path pathByDeletingLastPathComponent] 
																									 inStore: store];
	
	COSubtree *item = [[parentCtx persistentRootTree] subtreeWithUUID: [path lastPathComponent]];
	
	[[COSubtreeFactory factory] undo: item store: store];
	[parentCtx commitWithMetadata: nil];
	[[NSApp delegate] reloadAllBrowsers];
}

- (IBAction) redo: (id)sender
{
	COPersistentRootEditingContext *parentCtx = [COPersistentRootEditingContext editingContextForEditingPath: [path pathByDeletingLastPathComponent] 
																									 inStore: store];
	
	COSubtree *item = [[parentCtx persistentRootTree] subtreeWithUUID: [path lastPathComponent]];
	
	[[COSubtreeFactory factory] redo: item store: store];
	[parentCtx commitWithMetadata: nil];
	[[NSApp delegate] reloadAllBrowsers];
}

- (IBAction) switchToCommit: (id)sender
{
	ETUUID *commit = [sender representedObject];
	
	COPersistentRootEditingContext *parentCtx = [COPersistentRootEditingContext editingContextForEditingPath: [path pathByDeletingLastPathComponent] 
																									 inStore: store];
	
	COSubtree *persistentRootTree = [parentCtx persistentRootTree];
	COSubtree *item = [persistentRootTree subtreeWithUUID: [path lastPathComponent]];
	
	[[COSubtreeFactory factory] setCurrentVersion: commit
						forBranchOrPersistentRoot: item
											store: store];
	
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

- (void) expandParentsOfItem: (EWPersistentRootOutlineRow *)item
{
	NSMutableArray *anArray = [NSMutableArray array];

	// Note we must not try to expand outlineModel because it is
	// not an item the NSOutlineView is aware of, and trying to
	// do so seems to mess up the GNUstep outline view.
	
	for (EWPersistentRootOutlineRow *parent = [item parent]; 
		 parent != nil && parent != outlineModel;
		 parent = [parent parent])
	{
		[anArray addObject: parent];
	}
		 
	for (id row in [anArray reverseObjectEnumerator])
	{
	  [outlineView expandItem: row];
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
	
	[self expandParentsOfItem: row];
	
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

/* NSOutlineView Target/Action */

- (void)doubleClick: (id)sender
{
	if (sender == outlineView)
	{
		EWPersistentRootOutlineRow *row = [self selectedItem];
		
		NSLog(@"Double click %@", [row UUID]);
		
		if ([row attribute] == nil) // only if we click on the root of an embedded object
		{
			COSubtree *item = [[ctx persistentRootTree] subtreeWithUUID: [row UUID]];
			
			if ([[COSubtreeFactory factory] isPersistentRoot: item] ||
				[[COSubtreeFactory factory] isBranch: item])
			{
				[[NSApp delegate] browsePersistentRootAtPath: [path pathByAppendingPathComponent: [row UUID]]];
			}
		}
		
		// FIXME:
		// setting a double action on an outline view seems to break normal editing
		// so we hack it in here.
	}
}

- (NSArray *)selectedRows
{
	NSMutableArray *result = [NSMutableArray array];
	
	NSIndexSet *selIndexes = [outlineView selectedRowIndexes];
	
	for (NSUInteger i = [selIndexes firstIndex]; i != NSNotFound; i = [selIndexes indexGreaterThanIndex: i])
	{
		[result addObject: [outlineView itemAtRow: i]];
	}
	
	return [NSArray arrayWithArray: result];
}

- (void)deleteForward:(id)sender
{
	for (EWPersistentRootOutlineRow *itemToDelete in [self selectedRows])
	{
		if (itemToDelete != outlineModel)
		{
			[itemToDelete deleteRow];
		}
	}
	[[NSApp delegate] reloadAllBrowsers];
}

- (void)delete:(id)sender
{
	[self deleteForward: sender];
}

- (void)keyDown:(NSEvent *)theEvent
{
	[self interpretKeyEvents: [NSArray arrayWithObject:theEvent]];
}

/* NSOutlineView data source */

- (NSInteger) outlineView: (NSOutlineView *)anOutlineView numberOfChildrenOfItem: (id)item
{
	return [[[self modelForItem: item] children] count];
}

- (id) outlineView: (NSOutlineView *)anOutlineView child: (NSInteger)index ofItem: (id)item
{
	return [[[self modelForItem: item] children] objectAtIndex: index];
}

- (BOOL) outlineView: (NSOutlineView *)anOutlineView isItemExpandable: (id)item
{
	return [self outlineView: anOutlineView numberOfChildrenOfItem: item] > 0;
}

- (id) outlineView: (NSOutlineView *)anOutlineView objectValueForTableColumn: (NSTableColumn *)column byItem: (id)item
{
	return [[self modelForItem: item] valueForTableColumn: column];
}

/* Drag & Drop */

- (BOOL)outlineView:(NSOutlineView *)anOutlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pb
{
/*
	NSMutableArray *pbItems = [NSMutableArray array];

	if ([items count] == 0) return;
	
	EWPersistentRootOutlineRow *firstItem = [items objectAtIndex: 0];
	
	for (EWPersistentRootOutlineRow *row in items)
	{    
		if ([row parent] != [firstItem parent]) // Keep things simple by only allowing multiple rows if they are siblings
		{
			return NO;
		}
		
		NSPasteboardItem *item = [[[NSPasteboardItem alloc] init] autorelease];
		[item setPropertyList: [NSNumber numberWithInteger: (NSInteger)row]
					  forType: EWDragType];
		[pbItems addObject: item];
	}
	
	[pb clearContents];
	return [pb writeObjects: pbItems];
*/
	return NO;
}

- (NSDragOperation)outlineView:(NSOutlineView *)anOutlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
/*
	if (item != nil && ![item isKindOfClass: [EWPersistentRootOutlineRow class]])
	{
		return NSDragOperationNone;
	}
	for (NSPasteboardItem *pbItem in [[info draggingPasteboard] pasteboardItems])
	{
		EWPersistentRootOutlineRow *srcItem = (EWPersistentRootOutlineRow*)[[pbItem propertyListForType: EWDragType] integerValue];
		
		// Ensure the destination isn't a child of, or equal to, the source    
		for (EWPersistentRootOutlineRow *tempDest = item; tempDest != nil; tempDest = [tempDest parent])
		{
			if (tempDest == srcItem)
			{
				return NSDragOperationNone;
			}
		}
	}
	return NSDragOperationPrivate;
*/	
	return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)newParent childIndex:(NSInteger)index
{
	return NO;

/*
	newParent = [self modelForItem: newParent];
	
	NSUInteger insertionIndex = index;
	
	NSMutableIndexSet *newSelectedRows = [NSMutableIndexSet indexSet];
	NSMutableArray *outlineItems = [NSMutableArray array];
	
	for (NSPasteboardItem *pbItem in [[info draggingPasteboard] pasteboardItems])
	{
		[outlineItems addObject: (EWPersistentRootOutlineRow*)[[pbItem propertyListForType: EWDragType] integerValue]];
	}
	
	return NO;

*/
	
	// Make a link if the user is holding control 
	/*
	if ([info draggingSourceOperationMask] == NSDragOperationLink &&
		![[outlineItems objectAtIndex: 0] isKindOfClass: [ItemReference class]]) // Don't make links to link objects
	{
		OutlineItem *itemToLinkTo = [outlineItems objectAtIndex: 0];
		
		if (insertionIndex == -1) { insertionIndex = [[newParent contents] count]; }
		
		ItemReference *ref = [[ItemReference alloc] initWithParent: newParent
													referencedItem: itemToLinkTo
														   context: [[self rootObject] objectContext]];
		[ref autorelease];
		
		[newParent addItem: ref 
				   atIndex: insertionIndex]; 
		
		[self commitWithType: kCOTypeMinorEdit
			shortDescription: @"Drop Link"
			 longDescription: [NSString stringWithFormat: @"Drop Link to %@ on %@", [itemToLinkTo label], [newParent label]]];
		
		return;
	}
	
	// Here we only work on the model.
	
	for (OutlineItem *outlineItem in outlineItems)
	{
		OutlineItem *oldParent = [outlineItem parent];
		NSUInteger oldIndex = [[oldParent contents] indexOfObject: outlineItem];
		
		NSLog(@"Dropping %@ from %@", [outlineItem label], [oldParent label]);
		if (insertionIndex == -1) { insertionIndex = [[newParent contents] count]; }
		
		if (oldParent == newParent && insertionIndex > oldIndex)
		{
			[oldParent removeItemAtIndex: oldIndex];
			[newParent addItem: outlineItem atIndex: insertionIndex-1]; 
		}
		else
		{
			[oldParent removeItemAtIndex: oldIndex];
			[newParent addItem: outlineItem atIndex: insertionIndex++]; 
		}
	}
	
	[self commitWithType: kCOTypeMinorEdit
		shortDescription: @"Drop Items"
		 longDescription: [NSString stringWithFormat: @"Drop %d items on %@", (int)[outlineItems count], [newParent label]]];
	
	[outlineView expandItem: newParent];
	
	for (OutlineItem *outlineItem in outlineItems)
	{
		[newSelectedRows addIndex: [outlineView rowForItem: outlineItem]];
	}  
	[outlineView selectRowIndexes: newSelectedRows byExtendingSelection: NO];
	
	return YES;*/
}


/* NSOutlineView delegate */

- (void)outlineView:(NSOutlineView *)anOutlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([[tableColumn identifier] isEqualToString: @"name"])
	{
		if ([cell isKindOfClass: [EWIconTextFieldCell class]])
		{
			[cell setImage: [item image]];
		}
	}
}

- (NSCell *)outlineView:(NSOutlineView *)anOutlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	return [item dataCellForTableColumn: tableColumn];
}

- (void)outlineView:(NSOutlineView *)anOutlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{
	[item setValue: object forTableColumn: tableColumn];
}

- (void)outlineViewItemDidCollapse: (NSNotification *)notif
{
	EWPersistentRootOutlineRow *anItem = [[notif userInfo] objectForKey: @"NSObject"];
	[self setExpanded: NO forRow: anItem];
}
- (void)outlineViewItemDidExpand: (NSNotification *)notif
{
	EWPersistentRootOutlineRow *anItem = [[notif userInfo] objectForKey: @"NSObject"];
	[self setExpanded: YES forRow: anItem];
}

- (NSOutlineView *)outlineView
{
	return outlineView;
}

/* Cut/Copy/Paste */

- (IBAction)copy:(id)sender
{
	NSArray *rows = [self selectedRows];
	
	if ([rows count] == 0)
	{
		NSLog(@"Nothing to copy");
		return;
	}
	if ([rows count] > 1)
	{
		NSLog(@"FIXME: only copying first item");
	}
	
	EWPersistentRootOutlineRow *row = [rows objectAtIndex: 0];
	if (![row isEmbeddedObject])
	{
		NSLog(@"Only embedded objects can be copied.");
		return;
	}
	
	COSubtree *subtreeToCopy = [row rowSubtree];
	id plistToCopy = [subtreeToCopy plist];
	
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	[pb declareTypes: A(EWDragType) owner: self];
	[pb setPropertyList: plistToCopy forType: EWDragType];
}

- (IBAction)paste:(id)sender
{
	NSLog(@"Paste!");
	
	// test paste destination
	
	NSArray *rows = [self selectedRows];
	
	if ([rows count] != 1)
	{
		NSLog(@"Select a single row, container property of EmbeddedItemm, to paste on to");
		return;
	}
	
	EWPersistentRootOutlineRow *row = [rows objectAtIndex: 0];
	
	COSubtree *rowSubtree = [row rowSubtree];
	
	if (![[rowSubtree typeForAttribute: [row attribute]] isEqual: [COType setWithPrimitiveType: [COType embeddedItemType]]])
	{
		NSLog(@"Dest row type is wrong");
		return;
	}

	// do the paste
	
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSString *bestType = [pb availableTypeFromArray: A(EWDragType)];
	if (bestType != nil)
	{
		id plist = [pb propertyListForType: EWDragType];

		COSubtree *pasteSubtree = [COSubtree subtreeWithPlist: plist];
		
		[rowSubtree addObject: pasteSubtree
		 toUnorderedAttribute: [row attribute]
						 type: [rowSubtree typeForAttribute: [row attribute]]]; 
		
		[ctx commitWithMetadata: nil];		
		[[NSApp delegate] reloadAllBrowsers];
	}
	else
	{
		NSLog(@"No suitable data on pasteboard");
	}
}

- (IBAction)cut:(id)sender
{
	[self copy: sender];
	[self delete: sender];
}

// User interface validation

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    SEL theAction = [anItem action];

	NSArray *rows = [self selectedRows];
	
	if (theAction == @selector(copy:) || theAction == @selector(cut:))
	{
		if ([rows count] != 1)
		{
			return NO;
		}
		
		EWPersistentRootOutlineRow *row = [rows objectAtIndex: 0];
		if (![row isEmbeddedObject])
		{
			return NO;
		}
		
		return YES;
	}
	else if (theAction == @selector(paste:))
	{
		NSArray *rows = [self selectedRows];
		
		if ([rows count] != 1)
		{
			return NO;
		}
		
		EWPersistentRootOutlineRow *row = [rows objectAtIndex: 0];
		COSubtree *rowSubtree = [row rowSubtree];
		
		if (![[rowSubtree typeForAttribute: [row attribute]] isEqual: [COType setWithPrimitiveType: [COType embeddedItemType]]])
		{
			return NO;
		}
		
		NSPasteboard *pb = [NSPasteboard generalPasteboard];
		return [pb availableTypeFromArray: A(EWDragType)] != nil;
	}
	
	return [self respondsToSelector: theAction];
}

@end
