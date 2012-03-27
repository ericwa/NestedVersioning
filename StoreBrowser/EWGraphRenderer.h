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
- (void) drawWithHighlightedCommit: (ETUUID*)aCommit;

- (ETUUID *)commitAtPoint: (NSPoint)aPoint;

- (NSRect) rectForCommit:(ETUUID *)aCommit;
- (NSArray *) commits;

@end
