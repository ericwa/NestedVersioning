#import <Cocoa/Cocoa.h>
#import "COPath.h"
#import "COStore.h"
#import "COPersistentRootEditingContext.h"
#import "COPersistentRootEditingContext+PersistentRoots.h"

@class EWPersistentRootWindowController;

@interface EWPersistentRootOutlineRow : NSObject
{
	COPersistentRootEditingContext *ctx;
	
	EWPersistentRootWindowController *windowController;
	
	EWPersistentRootOutlineRow *parent;
	
	ETUUID *UUID;
	NSString *attribute;
	BOOL isPrimitiveInContainer;
	NSUInteger index;
	
	NSMutableArray *contents;
}

+ (NSComparisonResult) compareUUID: (ETUUID*)uuid1 withUUID: (ETUUID *)uuid2;

- (EWPersistentRootOutlineRow *) parent;

- (COSubtree *)rowSubtree;

- (ETUUID *)UUID;
- (NSString *)attribute;
- (BOOL) isPrimitiveInContainer;

- (id)initWithContext: (COPersistentRootEditingContext *)aContext
			   parent: (EWPersistentRootOutlineRow *)aParent
	 windowController: (EWPersistentRootWindowController *)aController;

- (NSArray*)children;
- (id)valueForTableColumn: (NSTableColumn *)column;
- (void) setValue: (id)aValue forTableColumn: (NSTableColumn *)column;

- (NSImage *)image;

- (NSCell *)dataCellForTableColumn: (NSTableColumn *)column;

- (void) deleteRow;

- (id) identifier;

- (NSComparisonResult) compare: (id)anObject;

- (NSMenu *)menu;

- (NSArray *) orderedBranchesForSubtree: (COSubtree*)aPersistentRoot;

// Special row types

- (BOOL) isPersistentRoot;
- (BOOL) isBranch;
- (BOOL) isEmbeddedObject;

@end
