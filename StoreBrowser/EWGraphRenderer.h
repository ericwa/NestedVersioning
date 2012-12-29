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

- (COStore *)store;

- (NSSize) size;
- (void) drawWithHighlightedCommit: (COUUID*)aCommit;

- (COUUID *)commitAtPoint: (NSPoint)aPoint;

- (NSRect) rectForCommit:(COUUID *)aCommit;
- (NSArray *) commits;

@end
