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


// This makes no sense, because a branch is just a persistent root.
// If you want to make a path to it, just make a direct path to the branch...

//- (COPath *) pathByAppendingPathToCurrentVersionOfPersistentRoot: (ETUUID *)aPersistentRoot
//													atBranchUUID: (ETUUID *)aBranch;

// this also makes no sense..
// if a persistent root is pointing at a specific version, then it is pointing at that version
// if not, a path to that version going "through" the persistent root doesn't make a lot of sense.

//- (COPath *) pathByAppendingPathToPersistentRoot: (ETUUID *)aPersistentRoot
//									   atVersion: (ETUUID *)aVersion;

- (NSString *) stringValue;

@end
