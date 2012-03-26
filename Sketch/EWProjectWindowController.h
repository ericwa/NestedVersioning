#import <Cocoa/Cocoa.h>


@interface EWProjectWindowController : NSWindowController
{
	IBOutlet NSOutlineView *organizer;
	IBOutlet NSTableView *drawingsTable;
}

- (void) addGroup: (id)sender;

@end
