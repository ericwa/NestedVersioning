#import <Cocoa/Cocoa.h>

@class EWPersistentRootWindowController;

@interface EWUndoManager : NSObject
{
	EWPersistentRootWindowController *winController;
}

- (id) initWithWindowController: (EWPersistentRootWindowController *)aWinController;

- (void) undo;
- (void) redo;

- (BOOL) canUndo;
- (BOOL) canRedo;

- (NSString *) undoMenuItemTitle;
- (NSString *) redoMenuItemTitle;

@end
