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
	ASSIGN(expansion, [NSMutableDictionary dictionary]);
	
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
	[outlineView registerForDraggedTypes:
	 [NSArray arrayWithObject: EWDragType]];
	
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

/* NSOutlineView Target/Action */

- (void)doubleClick: (id)sender
{
	if (sender == outlineView)
	{
		EWPersistentRootOutlineRow *row = [self selectedItem];
		
		NSLog(@"Double click %@", [row UUID]);
		
		if ([row attribute] == nil) // only if we click on the root of an embedded object
		{
			COMutableItem *item = [ctx _storeItemForUUID: [row UUID]];
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

- (void)deleteForward:(id)sender
{
	EWPersistentRootOutlineRow *itemToDelete = [self selectedItem];
	if (itemToDelete != outlineModel)
	{
		[itemToDelete deleteRow];
	}
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
	return [[self modelForItem: item] valueForTableColumn: column];
}

/* Drag & Drop */

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pb
{
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
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
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
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)newParent childIndex:(NSInteger)index
{
	newParent = [self modelForItem: newParent];
	
	NSUInteger insertionIndex = index;
	
	NSMutableIndexSet *newSelectedRows = [NSMutableIndexSet indexSet];
	NSMutableArray *outlineItems = [NSMutableArray array];
	
	for (NSPasteboardItem *pbItem in [[info draggingPasteboard] pasteboardItems])
	{
		[outlineItems addObject: (EWPersistentRootOutlineRow*)[[pbItem propertyListForType: EWDragType] integerValue]];
	}
	
	return NO;
	
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
	return [item dataCellForTableColumn: tableColumn];
}

- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
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


@end
