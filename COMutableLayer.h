#import <Foundation/Foundation.h>
#import "COFaultProvider.h"

/**
 * a fault provider which implements mutability.
 * it is itself a fault provider
 */
@interface COMutableLayer : NSObject <COFaultProvider>
{
	
}

- (COItem*) itemForUUID: (ETUUID *)aUUID;

// tree mutation

- (void) move

@end
