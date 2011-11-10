#import <Foundation/Foundation.h>
#import "ETUUID.h"

/**
  Holds a path of the form
 
    path := ""                                        // empty path
          | "<path>/persistentRootUUID"               // current version of current branch of specified persistent root
 
 the persistentRootUUIDs may be uuids of either branches, or persistent roots with no branches.
 they can't be of persistent roots with branches, beacause if a persistent root has branches,
 the branches are what is updated on commit.
 
 note that you can always get the uuid of the root that owns a branch, because that is stored in the branch
 
 */
@interface COPath : NSObject <NSCopying>
{
	COPath *parent;
	ETUUID *persistentRoot;
}

/**
 * Returns the root path
 */
+ (COPath *) path;

+ (COPath *) pathWithString: (NSString*) pathString;

- (COPath *) pathByAppendingPersistentRoot: (ETUUID *)aPersistentRoot;


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

- (BOOL) isEmpty;

- (ETUUID *) lastPathComponent;
- (COPath *) pathByDeletingLastPathComponent;

@end
