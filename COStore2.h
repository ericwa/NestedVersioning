#import <Foundation/Foundation.h>

#import "COUUID.h"
#import "COPersistentRoot.h"
#import "COSQLiteStore.h"

@interface COStore : NSObject
{
    COSQLiteStore *store_;
    
    NSMutableDictionary *rootForUUID_;
}

- (id)initWithStore: (COSQLiteStore*)aStore;
- (COSQLiteStore*)store;

- (NSSet *) persistentRoots;

- (COPersistentRoot *) persistentRootWithUUID: (COUUID *)aUUID;

@end
