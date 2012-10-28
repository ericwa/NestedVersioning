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
    
    // Used for coloring the graph
    COPersistentRootStateToken *currentCommit_;
    NSArray *branchCommits_;
}

- (id) initWithCommits: (NSArray*)stateTokens
         branchCommits: (NSArray*)tokensOnBranch
         currentCommit: (COPersistentRootStateToken*)currentCommit
                 store: (COStore*)aStore;
- (void) layoutGraph;

- (COStore *)store;

- (NSSize) size;
- (void) draw;

- (COPersistentRootStateToken *)commitAtPoint: (NSPoint)aPoint;

- (NSRect) rectForCommit:(COPersistentRootStateToken *)aCommit;
- (NSArray *) commits;

@end
