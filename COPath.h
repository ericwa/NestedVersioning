#import <Foundation/Foundation.h>
#import "ETUUID.h"

/**

 
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
