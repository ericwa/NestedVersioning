#import <Foundation/Foundation.h>
#import "COFaultProvider.h"

/**
 * Tree node that gets its data from a fault provider. when the fault provider
 * changes, it needs to re-fetch the state.
 */
@interface COItemTree : NSObject
{
	id <COFaultProvider> faultProvider;
}
@end
