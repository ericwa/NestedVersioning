#import <Foundation/Foundation.h>
#import "COUUID.h"

@interface COPath : NSObject <NSCopying>
{
@private
	COUUID *persistentRoot_;
	COUUID *branch_;
	COUUID *embeddedObject_;
}

/**
 * Implicitly points to the root object of the current branch
 */
+ (COPath *) pathWithPersistentRoot: (COUUID *)aRoot;

/**
 * Implicitly points to the root object
 */
+ (COPath *) pathWithPersistentRoot: (COUUID *)aRoot
							 branch: (COUUID*)aBranch;

+ (COPath *) pathWithPersistentRoot: (COUUID *)aRoot
							 branch: (COUUID*)aBranch
					embdeddedObject: (COUUID *)anObject;

- (COPath *) pathWithNameMapping: (NSDictionary *)aMapping;

// string persistence

+ (COPath *) pathWithString: (NSString*) pathString;
- (NSString *) stringValue;

@end
