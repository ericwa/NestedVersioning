#import <Foundation/Foundation.h>
#import "COFaultProvider.h"

@interface COSubtreeDiff : NSObject
{
	ETUUID *root;
	NSMutableDictionary *itemDiffForUUID;
}

+ (COSubtreeDiff *) diffRootItem: (ETUUID*)rootA
				 withRootItem: (ETUUID*)rootB
			  inFaultProvider: (id<COFaultProvider>)providerA
			withFaultProvider: (id<COFaultProvider>)providerB;

@end
