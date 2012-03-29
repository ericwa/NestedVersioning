#import <Foundation/Foundation.h>
#import "COUUID.h"


/**
 * A path is an immutable object; it consists of zero or more "paths to parent directory"
 * (in other words, zero or more "../" elements at the start of a UNIX path)
 * followed by a sequence of UUID's, separated by forward slashes.
 *
 * 
 * There are 2 places where paths are used:
 *
 * 1. A COPersistentRootEditingContext instance has a path so you can create a
 *    context for editing a nested persistent root.
 *
 * 2. As a data type of a value in an item inside a persistent root.
 *    
 *    a) paths with a single element (basically just a UUID) are used for 
 *       weak references within that persistent root. For example, the
 *       "persistentRoot" item uses a single-element path to identify its
 *       current branch (instead of using, say, an array index.)
 *
 *    b) more complex paths (starting with "../", or having multiple elements)
 *       are used to create weak references which point outside of the persistent
 *       root they are in.
 */
@interface COPath : NSObject <NSCopying>
{
@private
	NSArray *elements;
	NSUInteger leadingPathsToParent; // number of "../" at the start of the path
}

/**
 * The unix path "./" (current directory)
 */
+ (COPath *) path;

+ (COPath *) pathWithString: (NSString*) pathString;

+ (COPath *) pathWithPathComponent: (COUUID*) aUUID;

+ (COPath *) pathToParent;

/**
 * Appends "../" to a path
 */
- (COPath *) pathByAppendingPathToParent;

- (COPath *) pathByAppendingPath: (COPath *)aPath;

- (COPath *) pathByAppendingPathComponent: (COUUID *)aPersistentRoot;

- (NSString *) stringValue;

- (BOOL) isEmpty;

- (BOOL) hasComponents;

/**
 * Path begins with one or more "../" elements
 */
- (BOOL) hasLeadingPathsToParent;

- (COUUID *) lastPathComponent;
- (COPath *) pathByDeletingLastPathComponent;

- (COPath *) pathByRenamingComponents: (NSDictionary *)aMapping;

@end
