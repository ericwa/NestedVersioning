#import <Foundation/Foundation.h>
#import "COUUID.h"

/**
 * Protocol an object must conform to be managed by a COEditingContext
 */
@protocol COManagedObject <NSObject>

/**
 * @return the UUID of the object. Must not change.
 */
- (COUUID *) UUID;

/**
 * Do not call, called by context
 */
- (void) setContext: (id)aContext;
- (id) context;

- (void) setItem: (COItem *)anItem;

@end
