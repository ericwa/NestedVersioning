#import <Foundation/Foundation.h>
#import "ETUUID.h"


/**
 * A path consists of zero or more "../"'s followed by a sequence of UUID's
 * separated by forward slashes
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

+ (COPath *) pathWithPathComponent: (ETUUID*) aUUID;

+ (COPath *) pathToParent;

/**
 * Appends "../" to a path
 */
- (COPath *) pathByAppendingPathToParent;

- (COPath *) pathByAppendingPath: (COPath *)aPath;

- (COPath *) pathByAppendingPathComponent: (ETUUID *)aPersistentRoot;

- (NSString *) stringValue;

- (BOOL) isEmpty;

- (BOOL) hasComponents;

/**
 * Path begins with one or more "../" elements
 */
- (BOOL) hasLeadingPathsToParent;

- (ETUUID *) lastPathComponent;
- (COPath *) pathByDeletingLastPathComponent;

- (COPath *) pathByRenamingComponents: (NSDictionary *)aMapping;

@end
