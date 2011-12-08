#import "EWPersistentRootWindowController.h"
#import "COMacros.h"
#import <AppKit/NSOutlineView.h>


@implementation EWPersistentRootWindowController

- (void) setupCtx
{
	ASSIGN(ctx, [COPersistentRootEditingContext	editingContextForEditingPath: path
																	 inStore: store]);
	assert(ctx != nil);
	
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
		return [@"Persistent Root " stringByAppendingString: [path stringValue]];
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
	
	
	[[self window] setTitle: [self persistentRootTitle]];
}

- (IBAction) highlightInParent: (id)sender
{
	assert(![path isEmpty]);
	
	[[[NSApp delegate] windowControllerForPath: [path pathByDeletingLastPathComponent]] 
		orderFrontAndHighlightItem: [path lastPathComponent]];
}

- (IBAction) undo: (id)sender
{
	NSLog(@"Unimplemented");
}

- (IBAction) redo: (id)sender
{
	NSLog(@"Unimplemented");
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
	if ([[tableColumn identifier] isEqualToString: @"action"])
	{
		if ([item attribute] == nil) // only if we click on the root of an embedded object
		{
			COStoreItem *storeItem = [ctx _storeItemForUUID: [item UUID]];
			if ([[storeItem valueForAttribute: @"type"] isEqualToString: @"persistentRoot"] ||
				[[storeItem valueForAttribute: @"type"] isEqualToString: @"branch"])
			{
				NSString *msg;
				
				if ([[storeItem valueForAttribute: @"type"] isEqualToString: @"persistentRoot"])
				{
					msg = @"Open Current Branch";
				}
				else
				{
					msg = @"Open";
				}
				
				NSButtonCell *cell = [[[NSButtonCell alloc] init] autorelease];
				[cell setBezelStyle: NSRoundRectBezelStyle];
				[cell setTitle: msg];
				[cell setTarget: self];
				[cell setAction: @selector(openPersistentRoot:)];
				return cell;
			}
		}
	}
	
	return [tableColumn dataCell];
}

/** @taskunit open button */

- (void)openPersistentRoot: (id)sender
{
	EWPersistentRootOutlineRow *row = [self selectedItem];
	
	[[NSApp delegate] browsePersistentRootAtPath: [path pathByAppendingPathComponent: [row UUID]]];
}

@end
