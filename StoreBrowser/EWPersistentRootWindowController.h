#import <Cocoa/Cocoa.h>
#import <NestedVersioning/NestedVersioning.h>

#import "EWPersistentRootOutlineRow.h"

#define EWDragType @"org.etoile.storebrowser.rows"

@interface EWPersistentRootWindowController : NSWindowController
{
    COPersistentRoot *root;
    COBranch *branch;	
	COEditingContext *ctx;
    
	EWPersistentRootOutlineRow *outlineModel;
	IBOutlet NSOutlineView *outlineView;
}

- (NSOutlineView *)outlineView;

- (id)initWithPersistentRoot: (COPersistentRoot *)aRoot;

- (IBAction) highlightInParent: (id)sender;
- (IBAction) undo: (id)sender;
- (IBAction) redo: (id)sender;
- (IBAction) insertItem: (id)sender;


- (void) orderFrontAndHighlightItem: (COUUID*)aUUID;

/**
 * Temporary hack...
 */
- (void) reloadBrowser;

- (COUUID *) currentCommit;

- (NSArray *)selectedRows;

// private

- (void) reloadBrowser;
- (NSOutlineView *)outlineView;

@end


