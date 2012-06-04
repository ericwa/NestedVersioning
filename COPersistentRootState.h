#import <Foundation/Foundation.h>

@class COSubtree;

/**
 * Contents of a persistent roots.
 *
 * Size is O(number of items in state * size of item data); i.e. it is the full
 * data contents and potentially in the megabytes.
 */
@interface COPersistentRootState : NSObject
{
    COSubtree *tree;
}

- (id) initWithPlist: (NSDictionary *)aPlist;
- (id) plist;

- (COSubtree *) tree;
+ (COPersistentRootState *) stateWithTree: (COSubtree *)aTree;
@end
