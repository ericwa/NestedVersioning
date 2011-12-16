#import <Foundation/Foundation.h>
#import "COItem.h"
#import "ETUUID.h"

@protocol COFaultProvider <NSObject>

/**
 * Interface for the fault observer to get rows from the fault provider
 */
- (COItem*) itemForUUID: (ETUUID *)aUUID;

- (ETUUID *) rootItemUUID;

@end
