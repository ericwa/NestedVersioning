#import <Cocoa/Cocoa.h>
//#define EWDragType @"org.etoile.storebrowser.rows"

#import "EWTextStorage.h"
#import "EWTextView.h"

@interface EWTypewriterWindowController : NSWindowController
{
    IBOutlet EWTextView *textView_;
    
    EWTextStorage *textStorage_;
    
    BOOL isLoading_;
    
//	COPath *path;
//	COStore *store;
//	COPersistentRootEditingContext *ctx;
//	EWPersistentRootOutlineRow *outlineModel;
//	IBOutlet NSOutlineView *outlineView;
//	
//	IBOutlet EWHistoryGraphView *historyView;
//	
//	IBOutlet NSButton *highlightInParentButton;
//	IBOutlet NSButton *undoButton;
//	IBOutlet NSButton *redoButton;
//	IBOutlet NSSplitView *splitter;
//	
//	NSMutableDictionary *expansion;
}

//- (NSOutlineView *)outlineView;
//
//- (BOOL) isExpanded: (EWPersistentRootOutlineRow*)aRow;
//- (void) setExpanded: (BOOL)flag
//			 forRow: (EWPersistentRootOutlineRow *)aRow;
//
//- (id)initWithPath: (COPath*)aPath
//			 store: (COStore*)aStore;
//
//- (IBAction) highlightInParent: (id)sender;
//- (IBAction) undo: (id)sender;
//- (IBAction) redo: (id)sender;
//
//- (void) orderFrontAndHighlightItem: (COUUID*)aUUID;
//
//- (COSubtree *)branchItem;
//
///**
// * Temporary hack...
// */
//- (void) reloadBrowser;
//
//- (COUUID *) currentCommit;
//
//- (NSArray *)selectedRows;

- (void) loadDocumentTree: (COSubtree *)aTree;

@end


