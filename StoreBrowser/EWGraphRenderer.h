#import <Cocoa/Cocoa.h>
#import "COStore.h"

@interface EWGraphRenderer : NSObject
{
	NSSize size;
	NSArray *allCommitsSorted;
	NSMutableDictionary *childrenForUUID;
	NSMutableDictionary *levelForUUID;
	NSUInteger maxLevelUsed;
}

- (void) layoutGraphOfStore: (COStore*)aStore;

- (NSSize) size;
- (void) draw;

@end
