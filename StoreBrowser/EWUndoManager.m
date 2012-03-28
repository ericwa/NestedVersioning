#import "EWUndoManager.h"
#import "COStore.h"
#import "COSubtree.h"
#import "COSubtreeFactory+Undo.h"
#import "COMacros.h"

@implementation EWUndoManager

- (id) initWithWindowController: (EWPersistentRootWindowController *)aWinController
{
	SUPERINIT;
	winController = aWinController;
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (BOOL) canUndo
{
	return [winController canUndo];
}

- (BOOL) canRedo
{
	return [winController canRedo];
}

- (NSString *) undoMenuItemTitle
{
	return [winController undoLabel];
}
- (NSString *) redoMenuItemTitle
{
	return [winController redoLabel];
}

- (NSString *)undoMenuTitleForUndoActionName: (NSString *)action
{
	// FIXME: Hack...
	return [self undoMenuItemTitle];
}

- (NSString *)redoMenuTitleForUndoActionName: (NSString *)action
{
	// FIXME: Hack...
	return [self redoMenuItemTitle];
}

- (void) undo
{
	[winController undo: nil];
}

- (void) redo
{
	[winController redo: nil];	
}

@end
