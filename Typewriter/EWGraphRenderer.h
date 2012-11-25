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
    CORevisionID *currentCommit_;
    NSArray *branchCommits_;
}

- (id) initWithCommits: (NSArray*)stateTokens
         branchCommits: (NSArray*)tokensOnBranch
         currentCommit: (CORevisionID*)currentCommit
                 store: (COStore*)aStore;
- (void) layoutGraph;

- (COStore *)store;

- (NSSize) size;
- (void) drawWithHighlightedCommit: (CORevisionID *)aCommit;

- (CORevisionID *)commitAtPoint: (NSPoint)aPoint;

- (NSRect) rectForCommit:(CORevisionID *)aCommit;
- (NSArray *) commits;

@end
