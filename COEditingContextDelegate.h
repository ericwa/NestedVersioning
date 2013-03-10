#import <Foundation/Foundation.h>
#import "COManagedObject.h"
#import "COItem.h"

@protocol COEditingContextDelegate <NSObject>

/**
 * If the delegate return nil, COEditingContext will create a COObject
 * instance.
 */
- (id<COManagedObject>) createManagedObjectForItem: (COItem *)anItem;

@end
