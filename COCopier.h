#import <Foundation/Foundation.h>
#import "COItemGraph.h"

// TODO: Store the state relating to copying, e.g. which context to copy into.

@interface COCopier : NSObject

// TODO: Implement
- (id) initWithDestinationGraph: (id<COItemGraph>)dest;

/**
 * Basic copying method implementing the semantics in "copy semantics.key".
 *
 * Handles copying into the same context, or another one.
 */
- (ETUUID*) copyItemWithUUID: (ETUUID*)aUUID
                   fromGraph: (id<COItemGraph>)source
                     toGraph: (id<COItemGraph>)dest;
@end
