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

- (id) initWithCommits: (NSArray*)stateTokens store: (COStore*)aStore;
- (void) layoutGraph;

- (COStore *)store;

- (NSSize) size;
- (void) drawWithHighlightedCommit: (COPersistentRootStateToken*)aCommit;

- (COPersistentRootStateToken *)commitAtPoint: (NSPoint)aPoint;

- (NSRect) rectForCommit:(COPersistentRootStateToken *)aCommit;
- (NSArray *) commits;

@end
