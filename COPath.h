#import <Foundation/Foundation.h>
#import "ETUUID.h"

/**
 * simply an array of uuid's
 */
@interface COPath : NSObject
{
	NSArray *array;
}

+ (COPath *) pathWithParent: (COPath *)parent
		 persistentRootUUID: (ETUUID *)aUUID
				 branchUUID: (ETUUID *)aBranch;

@end
