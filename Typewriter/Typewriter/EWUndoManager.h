#import <Cocoa/Cocoa.h>

@interface EWUndoManager : NSObject
{
}

- (void) undo;
- (void) redo;

- (BOOL) canUndo;
- (BOOL) canRedo;

- (NSString *) undoMenuItemTitle;
- (NSString *) redoMenuItemTitle;

@end
