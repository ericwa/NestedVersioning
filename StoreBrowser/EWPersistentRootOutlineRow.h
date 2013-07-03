#import <Cocoa/Cocoa.h>
#import <NestedVersioning/NestedVersioning.h>

@class EWPersistentRootWindowController;

@interface EWPersistentRootOutlineRow : NSObject
{
	COObjectGraphContext *ctx;
	
	EWPersistentRootWindowController *windowController;
	
	EWPersistentRootOutlineRow *parent;
	
	COUUID *UUID;
	NSString *attribute;
	BOOL isPrimitiveInContainer;
	NSUInteger index;
	
	NSMutableArray *contents;
}

+ (NSComparisonResult) compareUUID: (COUUID*)uuid1 withUUID: (COUUID *)uuid2;

- (EWPersistentRootOutlineRow *) parent;

- (COObject *)rowSubtree;

- (COUUID *)UUID;
- (NSString *)attribute;
- (BOOL) isPrimitiveInContainer;

- (id)initWithContext: (COObjectGraphContext *)aContext
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

- (NSArray *) orderedBranchesForSubtree: (COObject*)aPersistentRoot;

// Special row types

- (BOOL) isEmbeddedObject;

- (void) commitWithMetadata: (NSDictionary*)meta;

@end
