#import <Foundation/Foundation.h>

@class COPath;
@class COStore;
@class COSubtree;
@class COSubtreeDiff;
@class COUUID;

/*
 test cases:
 
 
 photo-library (persistent root)
  |
   \-- photo (persistent root)
 
 
 1. two branches of photo-library where the _current branch of photo_ differs
 2. two branches of photo-library where photo has diverging edits made on the same branch (Y-shaped commit graph)
 3. two branches of photo-library where photo has non-diverging edits made on the same branch (straight-line commit graph)
 4. ???
  
 -----
 
 creation cases:
- create on a pair of persistent roots. user selects "diff all branches"?
- create on a pair of persistent roots. user selects "diff only current branch"?
- only allow creation on a pair of branches?
 
 tangent: there will need to be a UI option: "[ x ]  merge all branches of embedded persistent roots (as opposed to only merging current branches)"
 
 
 */
@interface COPersistentRootDiff : NSObject <NSCopying>
{
	NSMutableDictionary *subtreeDiffForPath;
	
	// FIXME: we will need to record the merge parents when
	// resolving a "set currentVersion" conflict
	//
	//NSMutableDictionary *mergeParentsForNewCommitUUID;
}

+ (COPersistentRootDiff *) diffSubtree: (COSubtree *)subtreeA
						   withSubtree: (COSubtree *)subtreeB
								 store: (COStore *)aStore
					  sourceIdentifier: (id)aSource;

#pragma mark diff application

- (COUUID *) commitAppliedToParent: (COUUID *)aParent
							 store: (COStore *)aStore;

#pragma mark access

/**
 * YES iff. any subtree diffs have conflicts
 */
- (BOOL) hasConflicts;

/**
 * 
 */
- (NSSet *) paths;

- (COSubtreeDiff *) subtreeDiffAtPath: (COPath *)aPath;

#pragma mark merge

- (void)mergeWithDiff: (COPersistentRootDiff *)other;
- (COPersistentRootDiff *)persistentRootDiffByMergingWithDiff: (COPersistentRootDiff *)other;

@end
