#import "EWOutlineView.h"

@implementation EWOutlineView

- (NSMenu *) menuForEvent: (NSEvent *)theEvent
{
    NSPoint pt = [self convertPoint: [theEvent locationInWindow] 
						   fromView: nil];
    id item = [self itemAtRow: [self rowAtPoint: pt]];
    return [item menu];
}

/**
 * Makes right click affect selection in the same way that left click does
 * (right click inside seletion: no change.
 *  right click outside selection: select row under right click)
 */
- (void)rightMouseDown:(NSEvent *)theEvent
{
    NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSUInteger row = [self rowAtPoint:pt];
	if (![self isRowSelected: row])
	{
		[self selectRowIndexes: [NSIndexSet indexSetWithIndex: row]
		  byExtendingSelection: NO];
	}
	[super rightMouseDown: theEvent];
}

// FIXME: Hack. NSWindow seems to implement -validateUserInterfaceItem:
// to check if the undo/redo menu items should be enabled, based on
// querying NSUndoManager. Since we don't use NSUndoManager, they're always
// disabled even though EWPersistentRootWindowController implements undo:/redo:.

- (IBAction) undo: (id)sender
{
	[[[self window] windowController] undo: sender];
}

- (IBAction) redo: (id)sender
{
	[[[self window] windowController] redo: sender];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    SEL theAction = [anItem action];
	
	if (theAction == @selector(undo:))
	{
		return [[[self window] windowController] canUndo];
	}
	else if (theAction == @selector(redo:))
	{
		return [[[self window] windowController] canRedo];
	}
	
	return YES;
}

@end
