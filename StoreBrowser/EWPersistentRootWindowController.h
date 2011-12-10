#import <Cocoa/Cocoa.h>
#import "COPath.h"
#import "COStore.h"
#import "COPersistentRootEditingContext.h"
#import "COPersistentRootEditingContext+Convenience.h"
#import "COPersistentRootEditingContext+PersistentRoots.h"

#import "EWPersistentRootOutlineRow.h"
#import "EWHistoryGraphView.h"

@interface EWPersistentRootWindowController : NSWindowController
{
	COPath *path;
	COStore *store;
	COPersistentRootEditingContext *ctx;
	EWPersistentRootOutlineRow *outlineModel;
	IBOutlet NSOutlineView *outlineView;
	
	IBOutlet EWHistoryGraphView *historyView;
	
	IBOutlet NSButton *highlightInParentButton;
	IBOutlet NSButton *undoButton;
	IBOutlet NSButton *redoButton;
}

- (id)initWithPath: (COPath*)aPath
			 store: (COStore*)aStore;

- (IBAction) highlightInParent: (id)sender;
- (IBAction) undo: (id)sender;
- (IBAction) redo: (id)sender;

- (void) orderFrontAndHighlightItem: (ETUUID*)aUUID;

/**
 * Temporary hack...
 */
- (void) reloadBrowser;

@end


