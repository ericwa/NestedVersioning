#import <Foundation/Foundation.h>

@interface COPersistentRootDiff : NSObject

/**
 * this class compares two persistent roots: (either two branches of the same persistent root, or
 * two separate persistent roots)
 *
 * the start of the algorithm is:
 *
 * diff-persistent-root(a, b):
 *     uuids-in-a = a set of the uuids of the embedded objects in a;
 *     uuids-in-b = a set of the uuids of the embedded objects in b;
 *
 *     uuids-in-both = uuids-in-a set-intersection uuids-in-b;
 *     uuids-deleted = uuids-in-a set-minus uuids-in-both;
 *     uuids-added = uuids-in-b set-minus uuids-in-both;
 *
 *     for each uuid in uuids-added, add a serialzed form of the object 
 *     to the edit script as an insertion operation.
 *
 *     add each uuid in uuids-deleted to the edit script as a deletion operation.
 *
 *     for each uuid in uuids-in-both:
 *         call diff-embedded-objects(version in a, version in b)
 *
 * well, that part of it is kind of trivial, most of the logic is in the diff-embedded-objects
 * function.
 *
 * Q: how should we deal with diffing embedded persistent roots?
 *    what about adding branches, deleting branches,
 *    modifying branches, changing the current branch,..
 * A: it should be a special case of diffing an embedded object,
 *    that handles all of the above scenarios, and also 
 *    calls diff-persistent-root on the embedded root.    
 *
 */

@end
