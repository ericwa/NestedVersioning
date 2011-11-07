#import <Foundation/Foundation.h>
#import "ETUUID.h"

/**
 * Holds a path of the form
 *
 *   path := ""                                        // empty path
 *         | "<path>/persistentRootUUID"               // current version of current branch of specified persistent root
 *         | "<path>/persistentRootUUID:branchUUID"    // current version of specified branch of specified persistent root
 *         | "<path>/persistentRootUUID@versionUUID"   // specified version of specified persistent root
 *
 */
@interface COPath : NSObject <NSCopying>
{
	COPath *parent;
	ETUUID *persistentRoot;
	ETUUID *branch;
	ETUUID *version;
}

/**
 * Returns an empty path
 */

+ (COPath *) path;

- (COPath *) pathByAppendingPathToCurrentVersionOfPersistentRoot: (ETUUID *)aPersistentRoot;

- (COPath *) pathByAppendingPathToCurrentVersionOfPersistentRoot: (ETUUID *)aPersistentRoot
													atBranchUUID: (ETUUID *)aBranch;

- (COPath *) pathByAppendingPathToPersistentRoot: (ETUUID *)aPersistentRoot
									   atVersion: (ETUUID *)aVersion;

- (NSString *) stringValue;

@end
