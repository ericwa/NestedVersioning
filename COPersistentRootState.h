#import <Foundation/Foundation.h>

@class COSubtree;
@class COPersistentRootStateToken;

/**
 * Contents of a persistent roots.
 *
 * Size is O(number of items in state * size of item data); i.e. it is the full
 * data contents and potentially in the megabytes.
 *
 * Also stores the parent commit link for our history graph / tree.
 * In that sense it combines the concept of commit and blob in git.
 *
 * Probably these should be factored into two concepts?
 */
@interface COPersistentRootState : NSObject
{
    COSubtree *tree_;
    COPersistentRootStateToken *parentStateToken_;
    NSDictionary *commitMetadata_;
}

- (id) initWithPlist: (NSDictionary *)aPlist;
- (id) plist;

- (NSDictionary *)commitMetadata;
- (void) setCommitMetadata: (NSDictionary*)commitMetadata;

- (COSubtree *) tree;
+ (COPersistentRootState *) stateWithTree: (COSubtree *)aTree;

- (void) setParentStateToken: (COPersistentRootStateToken *)aToken;
- (COPersistentRootStateToken *) parentStateToken;

@end
