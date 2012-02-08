#import "COSubtreeFactory.h"
#import "COStore.h"

@interface COSubtreeFactory (Pull)

- (void) pullChangesFromBranch: (COSubtree*)srcBranch
					  toBranch: (COSubtree*)destBranch
						 store: (COStore *)aStore;

@end
