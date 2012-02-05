#import <Foundation/Foundation.h>
#import "COStore.h"
#import "COFaultProvider.h"

/**
 * Simple adaptor class. No caching performed.
 */
@interface COStoreItemProvider : NSObject
{
	COStore *store;
	ETUUID *commit;
}

+ (COStoreItemProvider *) itemProviderWithStore: (COStore*)aStore
										 commit: (ETUUID*)aCommit;

- (COItem*) itemForUUID: (ETUUID *)aUUID;

@end
