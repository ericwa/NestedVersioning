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
 * The unix path "./" (current directory)
 */
+ (COPath *) path;

+ (COPath *) pathWithString: (NSString*) pathString;

/**
 * Appends "../" to a path
 */
- (COPath *) pathByAppendingPathToParent;

- (COPath *) pathByAppendingPath: (COPath *)aPath;

- (COPath *) pathByAppendingPathComponent: (ETUUID *)aPersistentRoot;

/**
 * Removes any non-leading ../ path elements.
 *
 * e.g. "../../projects/work/../fun/" is converted to "../../projects/fun"
 */
- (COPath *) normalizedPath;


- (NSString *) stringValue;

- (BOOL) isEmpty;

- (ETUUID *) lastPathComponent;
- (COPath *) pathByDeletingLastPathComponent;

@end
