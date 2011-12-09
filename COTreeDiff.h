#import <Foundation/Foundation.h>
#import "COFaultProvider.h"

@interface COTreeDiff : NSObject

+ (COTreeDiff *) diffItemUUIDs: (NSSet*)aSet
			   inFaultProvider: (id<COFaultProvider>)providerA
			 withFaultProvider: (id<COFaultProvider>)providerB;

@end
