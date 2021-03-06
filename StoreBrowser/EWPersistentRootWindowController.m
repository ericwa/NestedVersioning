#import "EWPersistentRootWindowController.h"
#import <EtoileFoundation/Macros.h>
#import "AppDelegate.h"
#import "EWIconTextFieldCell.h"

@implementation EWPersistentRootWindowController

- (void) setupCtx
{
	DESTROY(outlineModel);
	outlineModel = [[EWPersistentRootOutlineRow alloc] initWithContext: ctx
																parent: nil
													  windowController: self];	
}

- (id)initWithPersistentRoot: (COPersistentRoot *)aRoot
{
	self = [super initWithWindowNibName: @"PersistentRootWindow"];
	
	ASSIGN(root, aRoot);
	ASSIGN(branch, [root currentBranch]);
    ASSIGN(ctx, [branch editingContext]);
	assert(ctx != nil);	
    
	[self setupCtx];
	
	return self;
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
	
	//[[self window] setTitle: [self persistentRootTitle]];
}

- (NSString *) windowTitleForDocumentDisplayName:(NSString *)displayName
{
    return [root name];
}

- (void) reloadBrowser
{
	[self setupCtx];
	[outlineView reloadData];
    NSLog(@"reloaded data");
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
    [self reloadBrowser];
}

- (void)delete:(id)sender
{
	[self deleteForward: sender];
}

- (void)deleteBackward:(id)sender
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
}
- (void)outlineViewItemDidExpand: (NSNotification *)notif
{
	EWPersistentRootOutlineRow *anItem = [[notif userInfo] objectForKey: @"NSObject"];
}

- (NSOutlineView *)outlineView
{
	return outlineView;
}

/* Cut/Copy/Paste */

- (IBAction)copy:(id)sender
{
//	NSArray *rows = [self selectedRows];
//	
//	if ([rows count] == 0)
//	{
//		NSLog(@"Nothing to copy");
//		return;
//	}
//	if ([rows count] > 1)
//	{
//		NSLog(@"FIXME: only copying first item");
//	}
//	
//	EWPersistentRootOutlineRow *row = [rows objectAtIndex: 0];
//	if (![row isEmbeddedObject])
//	{
//		NSLog(@"Only embedded objects can be copied.");
//		return;
//	}
//	
//	COObject *subtreeToCopy = [row rowSubtree];
//	id plistToCopy = [[subtreeToCopy itemTree] plist];
//	
//	NSPasteboard *pb = [NSPasteboard generalPasteboard];
//	[pb declareTypes: A(EWDragType) owner: self];
//	[pb setPropertyList: plistToCopy forType: EWDragType];
}

- (IBAction)paste:(id)sender
{
//	NSLog(@"Paste!");
//	
//	// test paste destination
//	
//	NSArray *rows = [self selectedRows];
//	
//	if ([rows count] != 1)
//	{
//		NSLog(@"Select a single row, container property of EmbeddedItemm, to paste on to");
//		return;
//	}
//	
//	EWPersistentRootOutlineRow *row = [rows objectAtIndex: 0];
//	
//	COSubtree *rowSubtree = [row rowSubtree];
//	
//	if (![[rowSubtree typeForAttribute: [row attribute]] isEqual: [COType setWithPrimitiveType: kCOCompositeReferenceType]])
//	{
//		NSLog(@"Dest row type is wrong");
//		return;
//	}
//
//	// do the paste
//	
//	NSPasteboard *pb = [NSPasteboard generalPasteboard];
//	NSString *bestType = [pb availableTypeFromArray: A(EWDragType)];
//	if (bestType != nil)
//	{
//		id plist = [pb propertyListForType: EWDragType];
//
//		COSubtree *pasteSubtree = [COSubtree subtreeWithPlist: plist];
//		
//		[rowSubtree addObject: pasteSubtree
//		 toUnorderedAttribute: [row attribute]
//						 type: [rowSubtree typeForAttribute: [row attribute]]]; 
//		
//		[ctx commitWithMetadata: nil];		
//		[[NSApp delegate] reloadAllBrowsers];
//	}
//	else
//	{
//		NSLog(@"No suitable data on pasteboard");
//	}
}

- (IBAction)cut:(id)sender
{
	[self copy: sender];
	[self delete: sender];
}


/* Drag & Drop */

- (BOOL)outlineView:(NSOutlineView *)anOutlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pb
{
//	if ([items count] != 1)
//	{
//		return NO;
//	}
//
//	EWPersistentRootOutlineRow *row = [items objectAtIndex: 0];
//	if (![row isEmbeddedObject])
//	{
//		NSLog(@"Only embedded objects can be copied.");
//		return NO;
//	}
//	
//	COSubtree *subtreeToCopy = [row rowSubtree];
//	id plistToCopy = [subtreeToCopy plist];
//	
//	[pb declareTypes: A(EWDragType) owner: self];
//	return [pb setPropertyList: plistToCopy forType: EWDragType];
}

- (NSDragOperation)outlineView:(NSOutlineView *)anOutlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
	// FIXME: gnustep should handle this
	
//	id plist = [[info draggingPasteboard] propertyListForType: EWDragType];
//	if (plist == nil)
//	{
//		return NSDragOperationNone;
//	}
//	
//	COSubtree *proposedSubtree = [COSubtree subtreeWithPlist: plist];
//	if ([[[item rowSubtree] UUID] isEqual: [proposedSubtree UUID]])
//	{
//		NSLog(@"Can't drop source onto itself");
//		return NSDragOperationNone;
//	}
//	
//	if ([item isEmbeddedObject]
//		|| [[[item rowSubtree] typeForAttribute: [item attribute]] isEqual: [COType setWithPrimitiveType: kCOCompositeReferenceType]])
//	{
//		NSDragOperation mask = NSDragOperationNone;
//		if ([[[item rowSubtree] root] containsSubtreeWithUUID: [proposedSubtree UUID]])
//		{
//			mask = [info draggingSourceOperationMask];
//		}
//		else
//		{
//			// cross-persistent-root; copy for familiarity's sake
//			mask = NSDragOperationCopy;
//		}
//		NSLog(@"returning %d", (int)mask);
//		return mask;
//	}
//	return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)aOutlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)newParent childIndex:(NSInteger)index
{
//			NSLog(@"got %d", (int)[info draggingSourceOperationMask]);
//	
//	NSPasteboard *pb = [info draggingPasteboard];
//	NSString *bestType = [pb availableTypeFromArray: A(EWDragType)];
//	if (bestType == nil)
//	{
//		return NO;
//	}
//
//	id plist = [pb propertyListForType: EWDragType];		
//	COSubtree *pasteSubtree = [COSubtree subtreeWithPlist: plist];
//	COSubtree *destsubtree = [newParent rowSubtree];
//	
//	BOOL mustCopy = ![[destsubtree root] containsSubtreeWithUUID: [pasteSubtree UUID]];
//	
//	// special case: branch pull
//	
//	if ([[COSubtreeFactory factory] isBranch: pasteSubtree]
//		&& [[COSubtreeFactory factory] isBranch: destsubtree])
//	{
//		[[COSubtreeFactory factory] pullChangesFromBranch: pasteSubtree
//												 toBranch: destsubtree 
//													store: [ctx store]];
//		
//	}
//	else
//	{
//		if ([info draggingSourceOperationMask] == NSDragOperationLink)
//		{
//			NSLog(@"Link unsupported");
//			return NO;
//		}
//		
//		if (mustCopy || [info draggingSourceOperationMask] == NSDragOperationCopy)
//		{
//			NSLog(@"copy");
//		}
//		else
//		{
//			NSLog(@"remove %@", pasteSubtree);
//			NSLog(@"before %@", [[newParent rowSubtree] root]);
//			[[[newParent rowSubtree] root] removeSubtreeWithUUID: [pasteSubtree UUID]];
//		}
//		
//		
//		[destsubtree addTree: pasteSubtree];
//	}
//	
//
//	NSLog(@"after %@", [ctx persistentRootTree]);	
//	
//	[ctx commitWithMetadata: nil];
//	
//	[[NSApp delegate] performSelector: @selector(reloadAllBrowsers) withObject:nil afterDelay:0.1];
//	
	return YES;
}




// User interface validation

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    SEL theAction = [anItem action];

	NSArray *rows = [self selectedRows];
//	
//	if (theAction == @selector(copy:) || theAction == @selector(cut:))
//	{
//		if ([rows count] != 1)
//		{
//			return NO;
//		}
//		
//		EWPersistentRootOutlineRow *row = [rows objectAtIndex: 0];
//		if (![row isEmbeddedObject])
//		{
//			return NO;
//		}
//		
//		return YES;
//	}
//	else if (theAction == @selector(paste:))
//	{
//		NSArray *rows = [self selectedRows];
//		
//		if ([rows count] != 1)
//		{
//			return NO;
//		}
//		
//		EWPersistentRootOutlineRow *row = [rows objectAtIndex: 0];
//		COSubtree *rowSubtree = [row rowSubtree];
//		
//		if (![[rowSubtree typeForAttribute: [row attribute]] isEqual: [COType setWithPrimitiveType: kCOCompositeReferenceType]])
//		{
//			return NO;
//		}
//		
//		NSPasteboard *pb = [NSPasteboard generalPasteboard];
//		return [pb availableTypeFromArray: A(EWDragType)] != nil;
//	}
	
	return [self respondsToSelector: theAction];
}

//- (NSUndoManager *)undoManager
//{
//	return [[[EWUndoManager alloc] initWithWindowController: self] autorelease];
//}
//
//- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender
//{
//	return [self undoManager];
//}

- (IBAction) undo: (id)sender
{
    
}
- (IBAction) redo: (id)sender
{
    
}
- (IBAction) insertItem: (id)sender
{
    EWPersistentRootOutlineRow *row = [[self selectedItem] parent];
    if (row != nil)
    {
        [[row rowSubtree] addObjectToContents: [[COObjectGraphContext editingContextWithItem: [COMutableItem item]] rootObject]];
        
        [branch commitChangesWithMetadata: nil];
        [self reloadBrowser];
        
    }
}

@end
