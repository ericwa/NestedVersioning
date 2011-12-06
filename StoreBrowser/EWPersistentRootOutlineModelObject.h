#import <Foundation/Foundation.h>
#import "COPath.h"
#import "COStore.h"
#import "COPersistentRootEditingContext.h"
#import "COPersistentRootEditingContext+Convenience.h"
#import "COPersistentRootEditingContext+PersistentRoots.h"

@interface EWPersistentRootOutlineModelObject : NSObject
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

@end
