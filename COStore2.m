#import "COStore.h"
#import "COMacros.h"
#import "COPersistentRootPrivate.h"
#import "COSQLiteStore.h"

@implementation COStore

- (id)initWithStore: (COSQLiteStore*)aStore
{
    self = [super init];
    rootForUUID_ = [[NSMutableDictionary alloc] init];
    ASSIGN(store_, aStore);
    return self;
}

- (COSQLiteStore*)store
{
    return store_;
}

- (void)dealloc
{
    [store_ release];
    [rootForUUID_ release];
    [super dealloc];
}

- (void) fetchPersistentRoots
{
    if (rootForUUID_ == nil)
    {
        
        {
            [self cachePersistentRootEditPlist: [store_ persistentRootWithUUID: uuid]];
        }
    }
}

- (COPersistentRoot *) cachePersistentRootEditPlist: (COPersistentRootState *)persistentRoot
{
    [self fetchPersistentRoots];
    
    COPersistentRoot *root = [[[COPersistentRoot alloc] initWithStoreEditQueue: self
                                                                persistentRoot: persistentRoot] autorelease];
    [rootForUUID_ setObject: root forKey: [root UUID]];
    return root;
}

- (NSSet *) persistentRoots
{
    [self fetchPersistentRoots];
    return [NSSet setWithArray: [rootForUUID_ allValues]];
}

- (COPersistentRoot *) persistentRootWithUUID: (COUUID *)aUUID
{
    [self fetchPersistentRoots];
    COPersistentRoot *root = [rootForUUID_ objectForKey: aUUID];
    return root;
}

@end
