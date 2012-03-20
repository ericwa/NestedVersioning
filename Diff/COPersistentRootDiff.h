#import <Foundation/Foundation.h>

@class COPath;
@class COStore;
@class COSubtree;
@class COSubtreeDiff;

/*
 void diff_branch_with_branch(branch_a_path, branch_b_path)
 {
 // record metadata changes normally.
 
 // for the branch contents:
 // first compute the referenced versions: branch_a_version, branch_b_version
 
 // IDEA:
 // next see if branch_b_version is a ancestor or descendent of branch_a_version.
 // --->problem is, that doesn't give any useful information when merging.
 //     i.e. 'branch diff A->B says "fast forward to X", branch diff A->C says
 //     "fast forward to Y"' is useless for merging. so we have to actually
 //     open the destination versions and diff them.
 
 // so next just do:
 // diff_version_with_version(branch_a_version, branch_b_version);
 }
 
 void diff_proot_with_proot(proot_a_path, proot_b_path)
 {
 // call diff_branch_with_branch on branches that appear in both proots.
 // otherwise, record the added/removed branches, and any other metadata changes, normally.
 } 
 
 
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
	// diff of the persistent root metatata
	
	
	
	/**
	 * YES if the receiver was created by diffing two branch objects,
	 * NO if created by diffing two persistent root objects
	 */
	BOOL wasCreatedFromBranches;
	
	/**
	 * diff of the branches or persistent root objects the receiver 
	 * was created with
	 */
	COSubtreeDiff *rootDiff;
	
	
	
	// diffs of the contents of the persistent root.
	
	
	
	/**
	 * never contains the empty path
	 *
	 * contains a single-element path for every currentVersion conflict in rootDiff
	 *
	 * this is only used for calculating merges.
	 */
	NSMutableDictionary *subtreeDiffForPath;
	
	
	/**
	 * this is only used for calculating merges.
	 */
	NSMutableDictionary *initialSubtreeForPath;
	
	
	
	// auxiliary stuff created when two diffs are merged
	
	

	NSMutableDictionary *parentCommitForPendingCommitUUID;	
	NSMutableDictionary *treeToCommitForPendingCommitUUID;
}

+ (COPersistentRootDiff *) diffPersistentRoot: (COSubtree *)rootA
						   withPersistentRoot: (COSubtree *)rootB
								  allBranches: (BOOL)allBranches
										store: (COStore *)aStore
							 sourceIdentifier: (id)aSource;


+ (COPersistentRootDiff *) diffBranch: (COSubtree *)branchA
						   withBranch: (COSubtree *)branchB
								store: (COStore *)aStore
					 sourceIdentifier: (id)aSource;

#pragma mark diff application

- (void) applyToPersistentRootOrBranch: (COSubtree *)dest
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

/**
 * diff of the branches or persistent root objects the receiver 
 * was created with
 */
- (COSubtreeDiff *) rootSubtreeDiff;
- (COSubtreeDiff *) subtreeDiffAtPath: (COPath *)aPath;
- (COSubtree *) initialSubtreeForPath: (COPath *)aPath;

#pragma mark merge

- (void)mergeWithDiff: (COPersistentRootDiff *)other;
- (COPersistentRootDiff *)persistentRootDiffByMergingWithDiff: (COPersistentRootDiff *)other;

@end
