#import "EWPersistentRootWindowController.h"
#import "Common.h"
#import <AppKit/NSOutlineView.h>


@implementation EWPersistentRootWindowController

- (void) setupCtx
{
	ASSIGN(ctx, [COPersistentRootEditingContext	editingContextForEditingPath: path
																	 inStore: store]);
	assert(ctx != nil);
	
	outlineModel = [[EWPersistentRootOutlineRow alloc] initWithContext: ctx];
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

- (void)awakeFromNib
{
	[outlineView setTarget: self];
	[outlineView setDoubleAction: @selector(doubleClick:)];
	
	{
		NSButtonCell *cell = [[[NSBrowserCell alloc] init] autorelease];
	
		[[outlineView tableColumnWithIdentifier: @"name"] setDataCell: cell];
	}
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
				NSLog(@"open root!");
				
				// FIXME: don't leak, move to app controller
				
				EWPersistentRootWindowController *wc = [[EWPersistentRootWindowController alloc] initWithPath: [path pathByAppendingPathComponent: [row UUID]]
																										store: store];
				
				[wc showWindow: nil];
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
	if ([cell isKindOfClass: [NSBrowserCell class]])
	{
		[cell setLeaf: YES];
		[cell setImage: [item image]];
	}
}


@end
