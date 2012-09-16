#import "EWUndoManager.h"

@implementation EWUndoManager

- (void) dealloc
{
	[super dealloc];
}

- (BOOL) canUndo
{
	return YES;
}

- (BOOL) canRedo
{
	return YES;
}

- (NSString *) undoMenuItemTitle
{
	return @"undo";
}
- (NSString *) redoMenuItemTitle
{
	return @"redo";
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
	NSLog(@"Undo");
}

- (void) redo
{
	NSLog(@"Redo");
}

- (void)forwardInvocation:(NSInvocation *)invocation {
}

- (id)prepareWithInvocationTarget:(id) target
{
    return self;
}

- (void)registerUndoWithTarget:(id)target selector:(SEL)aSelector object:(id)anObject
{
}

- (void)setActionName:(NSString*) actionName
{
    
}

@end
