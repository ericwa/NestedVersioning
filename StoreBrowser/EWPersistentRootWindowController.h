#import <Cocoa/Cocoa.h>
#import <NestedVersioning/NestedVersioning.h>

#import "EWPersistentRootOutlineRow.h"

#define EWDragType @"org.etoile.storebrowser.rows"

@interface EWPersistentRootWindowController : NSWindowController
{
    COPersistentRoot *root;
    COBranch *branch;	
	COObjectGraphContext *ctx;
    
	EWPersistentRootOutlineRow *outlineModel;
	IBOutlet NSOutlineView *outlineView;
}

- (NSOutlineView *)outlineView;

- (id)initWithPersistentRoot: (COPersistentRoot *)aRoot;

- (IBAction) highlightInParent: (id)sender;
- (IBAction) undo: (id)sender;
- (IBAction) redo: (id)sender;
- (IBAction) insertItem: (id)sender;


- (void) orderFrontAndHighlightItem: (ETUUID*)aUUID;

/**
 * Temporary hack...
 */
- (void) reloadBrowser;

- (ETUUID *) currentCommit;

- (NSArray *)selectedRows;

// private

- (void) reloadBrowser;
- (NSOutlineView *)outlineView;

@end


