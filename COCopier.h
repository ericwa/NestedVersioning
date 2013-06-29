#import <Foundation/Foundation.h>
#import "COItemGraph.h"

@interface COCopier : NSObject

/**
 * Basic copying method implementing the semantics in "copy semantics.key".
 *
 * Handles copying into the same context, or another one.
 */
- (COUUID*) copyItemWithUUID: (COUUID*)aUUID
                   fromGraph: (id<COItemGraph>)source
                     toGraph: (id<COItemGraph>)dest;
@end
