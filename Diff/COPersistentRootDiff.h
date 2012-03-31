#import <Foundation/Foundation.h>

@class COPath;
@class COStore;
@class COSubtree;
@class COSubtreeDiff;
@class COUUID;

/**
 * the whole point of this class is supporting merging;
 * if you don't need merging you can just use COSubtreeDiff
 * and it will handle changes in embedded persistent roots for free.
 *
 */
@interface COPersistentRootDiff : NSObject <NSCopying>
{
	// populated on diff
	NSMutableDictionary *subtreeDiffForPath;

	// populated on diff	
	NSMutableDictionary *diffBaseUUIDForPath;
	
	// populated on merge
	NSMutableDictionary *mergeParentsForNewCommitUUID;

	// populated on merge	
	NSMutableDictionary *newCommitUUIDForPath;
}

+ (COPersistentRootDiff *) diffCommit: (COUUID *)commitA
						   withCommit: (COUUID *)commitA
								store: (COStore *)aStore
					 sourceIdentifier: (id)aSource;

#pragma mark diff application

- (COUUID *) commitInStore: (COStore *)aStore;

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
