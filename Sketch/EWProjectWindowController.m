#import "EWProjectWindowController.h"
#import "EWCenteredTextFieldCell.h"
#import "COMacros.h"

@implementation EWProjectWindowController

- (id) init
{
	self = [super initWithWindowNibName: @"ProjectWindow"];
	if (nil != self)
	{

	}
	return self;
}

- (void)windowDidLoad
{
	[drawingsTable setRowHeight: 128];
	
	EWCenteredTextFieldCell *cell = [[[EWCenteredTextFieldCell alloc] init] autorelease];
	[cell setEditable: YES];
	[[drawingsTable tableColumnWithIdentifier: @"label"] setDataCell: cell];
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{
	if ([[splitView subviews] objectAtIndex: 0] == subview)
	{
		return NO;
	}
	return YES;
}

- (void) addGroup: (id)sender
{
	NSLog(@"Add group");
}

// NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return 1;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if ([[tableColumn identifier] isEqual: @"image"])
	{
		return [NSImage imageNamed: NSImageNameComputer];
	}
	else if ([[tableColumn identifier] isEqual: @"label"])
	{
		return @"Hello";
	}
	return nil;
}

// NSOutlineViewDataSource


- (NSInteger) outlineView: (NSOutlineView *)anOutlineView numberOfChildrenOfItem: (id)item
{
	if (item == nil)
	{
		return 2;
	}
	if ([item isEqual: @"Trash"])
	{
		return 1;
	}
	return 0;
}

- (id) outlineView: (NSOutlineView *)anOutlineView child: (NSInteger)index ofItem: (id)item
{
	if (item == nil)
	{
		return [A(@"All Drawings", @"Trash") objectAtIndex: index];
	}
	if ([item isEqual: @"Trash"])
	{
		return @"Hi";
	}
	return nil;
}

- (BOOL) outlineView: (NSOutlineView *)anOutlineView isItemExpandable: (id)item
{
	return [self outlineView: anOutlineView numberOfChildrenOfItem: item] > 0;
}

- (id) outlineView: (NSOutlineView *)anOutlineView objectValueForTableColumn: (NSTableColumn *)column byItem: (id)item
{
	return item;
}


@end
