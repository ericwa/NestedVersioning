#import <Foundation/Foundation.h>
#import "COFaultProvider.h"

@interface COTreeDiff : NSObject

+ (COTreeDiff *) diffRootItem: (ETUUID*)rootA
				 withRootItem: (ETUUID*)rootB
			  inFaultProvider: (id<COFaultProvider>)providerA
			withFaultProvider: (id<COFaultProvider>)providerB;

@end
