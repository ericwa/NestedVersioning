#import "EWPersistentRootWindowController.h"
#import "Common.h"
#import <AppKit/NSOutlineView.h>


@implementation EWPersistentRootWindowController

- (void) setupCtx
{
	ASSIGN(ctx, [COPersistentRootEditingContext	editingContextForEditingPath: path
																	 inStore: store]);
	assert(ctx != nil);
	
	outlineModel = [[EWPersistentRootOutlineModelObject alloc] initWithContext: ctx];
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



/* NSOutlineView data source */

- (EWPersistentRootOutlineModelObject *)modelForItem: (id)anItem
{
	EWPersistentRootOutlineModelObject *model = anItem;
	if (model == nil)
	{
		model = outlineModel;
	}
	return model;
}

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

@end
