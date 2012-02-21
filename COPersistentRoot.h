#import <Foundation/Foundation.h>

@class COSubtree;

/**
 * Object that encapsulates a persistent root's metadata
 * (i.e. the subtree
 *  { "type" : "persistentRoot";
 *    "currentBranch" : "xxx-yyy-zzz...";
 *    "branches" : ( { "type" : "branch"; ... }, ...) }
 *
 *    and all embedded commits (?)
 *
 */
@interface COPersistentRoot : NSObject
{
	COSubtree *contentTree;
	
	NSDictionary *embeddedPersistentRootForCommitUUID;
}




@end
