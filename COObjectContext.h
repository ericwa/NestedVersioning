#import <Foundation/Foundation.h>
#import "COPath.h"

/**
 * an object context handles the process of committing changes.
 *
 * committing to a persistent root nested several roots deep necessitates
 * commits in every parent.
 */
@interface COObjectContext : NSObject
{
	
}

+ (COObjectContext *)contextForEditingPersistentRootAtPath: (COPath *)aPath;

- (void) commit;

@end
