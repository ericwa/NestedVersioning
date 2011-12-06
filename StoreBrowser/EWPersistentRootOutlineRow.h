#import <Cocoa/Cocoa.h>
#import "COPath.h"
#import "COStore.h"
#import "COPersistentRootEditingContext.h"
#import "COPersistentRootEditingContext+Convenience.h"
#import "COPersistentRootEditingContext+PersistentRoots.h"

@interface EWPersistentRootOutlineRow : NSObject
{
	COPersistentRootEditingContext *ctx;
	
	ETUUID *UUID;
	NSString *attribute;
	BOOL isPrimitiveInContainer;
	NSUInteger index;
	
	NSMutableArray *contents;
}

- (ETUUID *)UUID;
- (NSString *)attribute;

- (id)initWithContext: (COPersistentRootEditingContext *)aContext;

- (NSArray*)children;
- (id)valueForTableColumn: (NSTableColumn *)column;

- (NSImage *)image;

@end
