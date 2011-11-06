#import <Foundation/Foundation.h>
#import "COPath.h"

/**
 * an object context handles the process of committing changes.
 *
 * committing to a persistent root nested several roots deep necessitates
 * commits in every parent.
 */
@interface COEditingContext : NSObject
{
	
}

/**
 * note that this will create implict/hidden contexts for committing 
 * to all of the intermetiate roots in the path. This is ok, but it means
 * other contexts already open on those roots might have to do a merge
 * to apply their changes (either a trivial merge, most likely, or a conflict)
 */
+ (COEditingContext *)contextForEditingPersistentRootAtPath: (COPath *)aPath;

- (void) commit;

@end
