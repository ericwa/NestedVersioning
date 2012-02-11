#import <Foundation/Foundation.h>

@class COSubtree;

@interface COPersistentRoot : NSObject
{
	COSubtree *contentTree;
	
	NSDictionary *embeddedPersistentRootForCommitUUID;
}


@end
