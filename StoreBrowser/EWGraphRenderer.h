#import <Cocoa/Cocoa.h>
#import "COStore.h"

@interface EWGraphRenderer : NSObject
{
	NSSize size;
	NSMutableArray *allCommitsSorted;
	NSMutableDictionary *childrenForUUID;
	NSMutableDictionary *levelForUUID;
	NSUInteger maxLevelUsed;
	COStore *store;
}

- (id) initWithStore: (COStore*)aStore;
- (void) layoutGraph;

- (NSSize) size;
- (void) drawWithHighlightedCommit: (ETUUID*)aCommit;

@end
