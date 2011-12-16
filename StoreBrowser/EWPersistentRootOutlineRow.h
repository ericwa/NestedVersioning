#import <Cocoa/Cocoa.h>
#import "COPath.h"
#import "COStore.h"
#import "COPersistentRootEditingContext.h"
#import "COPersistentRootEditingContext+Convenience.h"
#import "COPersistentRootEditingContext+PersistentRoots.h"

@interface EWPersistentRootOutlineRow : NSObject
{
	COPersistentRootEditingContext *ctx;
	
	EWPersistentRootOutlineRow *parent;
	
	ETUUID *UUID;
	NSString *attribute;
	BOOL isPrimitiveInContainer;
	NSUInteger index;
	
	NSMutableArray *contents;
}

- (EWPersistentRootOutlineRow *) parent;

- (ETUUID *)UUID;
- (NSString *)attribute;
- (BOOL) isPrimitiveInContainer;

- (id)initWithContext: (COPersistentRootEditingContext *)aContext
			   parent: (EWPersistentRootOutlineRow *)aParent;

- (NSArray*)children;
- (id)valueForTableColumn: (NSTableColumn *)column;
- (void) setValue: (id)aValue forTableColumn: (NSTableColumn *)column;

- (NSImage *)image;

- (NSCell *)dataCellForTableColumn: (NSTableColumn *)column;

- (void) deleteRow;

@end
