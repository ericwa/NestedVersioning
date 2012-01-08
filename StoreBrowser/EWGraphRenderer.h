#import <Cocoa/Cocoa.h>
#import "COStore.h"

@interface EWGraphRenderer : NSObject
{
	NSSize size;
	NSMutableArray *allCommitsSorted;
	NSMutableDictionary *childrenForUUID;
	NSMutableDictionary *levelForUUID;
	NSUInteger maxLevelUsed;
}

- (void) layoutGraphOfStore: (COStore*)aStore;

- (NSSize) size;
- (void) draw;

@end


/*
 Graph-drawing algorithm:
 
 1. Sort by date. Ensure the commits are topologically sorted.
 2. Create a set of branches, such that each commit is in exactly
    one branch, and the branches are "as long as possible".
    (given the input commit graph, the longest branch possible
     is generated greedily, then the next longest, etc.)
 3. 
 
 */

/**
 * Invariants: a branch is an ordered array of commits, where each 
 * commit's parent is the commit immediately preceding it in the array.
 * The branches are constructed to be as long as possible.
 *
 * e.g. for graph
 *
 *      /-->D-->E
 * A-->B-->C
 *
 * the set of branches generated would be {[A,B,D,E], [C]}, not {[A,B,C], [D,E]}
 */
@interface EWGraphBranchGenerator : NSObject
{
	NSMutableDictionary *branchForUUID;
}

- (NSUInteger) countOfCommitsInBranchForCommit: (ETUUID*)aCommit;
- (NSSet *) commitsInBranchForCommit: (ETUUID*)aCommit;

- (void) addCommit: (ETUUID*)aCommit
		withParent: (ETUUID*)aParent;

@end
