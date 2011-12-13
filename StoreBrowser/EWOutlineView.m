#import "EWOutlineView.h"

@implementation EWOutlineView

- (NSMenu*) defaultMenuFor: (id)row
{	
    NSMenu *menu = [[[NSMenu alloc] initWithTitle: @"Context menu"] autorelease];
    [menu insertItemWithTitle: @"Foo" 
					   action: @selector(foo:) 
				keyEquivalent: @"" 
					  atIndex: 0];
    [menu insertItemWithTitle: [NSString stringWithFormat:@"Bar"] 
					   action: @selector(bar:) 
				keyEquivalent: @"" 
					  atIndex: 0];
    return menu;
}

- (NSMenu *) menuForEvent: (NSEvent *)theEvent
{
    NSPoint pt = [self convertPoint: [theEvent locationInWindow] 
						   fromView: nil];
    id item = [self itemAtRow: [self rowAtPoint: pt]];
    return [self defaultMenuFor: item];
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

@end
