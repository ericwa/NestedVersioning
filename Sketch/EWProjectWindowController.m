#import "EWProjectWindowController.h"
#import "EWCenteredTextFieldCell.h"

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


@end
