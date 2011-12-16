#import "COStore.h"
#import "COPath.h"

@interface COStore (PersistentRootCommit)

- (ETUUID *) baseCommitForPath: (COPath*)aPath;

@end
