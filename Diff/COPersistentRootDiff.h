#import <Foundation/Foundation.h>

@class COPath;
@class COStore;

@interface COPersistentRootDiff : NSObject
{

}

// FIXME: another constructor that takes an in-memory COPersistentRoot?

- (id) initWithPath: (COPath *)aRootOrBranchA
			andPath: (COPath *)aRootOrBranchB
			inStore: (COStore *)aStore; 

@end
