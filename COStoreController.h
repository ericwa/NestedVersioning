#import <Foundation/Foundation.h>
#import "COStore.h"

/**
 * a store api one level higher than COStore..
 * probably this will become the real COStore api once we switch to sqlite again
 */
@interface COStoreController : NSObject
{
	COStore *store;
}
- (id)initWithStore: (COStore*)aStore;


@end
