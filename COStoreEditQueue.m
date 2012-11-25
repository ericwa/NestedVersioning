#import "COStoreEditQueue.h"
#import "COMacros.h"
#import "COEditQueuePrivate.h"
#import "COSQLiteStore.h"

@implementation COStoreEditQueue

- (id)initWithURL: (NSURL*)aURL
{
    SUPERINIT;
    store_ = [[COSQLiteStore alloc] initWithURL: aURL];
    rootForUUID_ = [[NSMutableDictionary alloc] init];
    return self;
}

- (void)dealloc
{
    [store_ release];
    [rootForUUID_ release];
    [super dealloc];
}

- (NSURL*)URL
{
    return [store_ URL];
}

- (NSArray *) allPersistentRootUUIDs
{
    return [store_ allPersistentRootUUIDs];
}

- (COPersistentRootEditQueue *) persistentRootEditQueue: (id<COPersistentRootMetadata>)persistentRoot
{
    COPersistentRootEditQueue *root = [[COPersistentRootEditQueue alloc] initWithStoreEditQueue: self
                                                                                 persistentRoot: persistentRoot];
    [rootForUUID_ setObject: root forKey: [root UUID]];
    [root release];
    return root;
}

- (COPersistentRootEditQueue *) persistentRootWithUUID: (COUUID *)aUUID
{
    COPersistentRootEditQueue *root = [rootForUUID_ objectForKey: aUUID];
    if (root == nil)
    {
        id<COPersistentRootMetadata> persistentRoot = [store_ persistentRootWithUUID: aUUID];
        if (persistentRoot != nil)
        {
            return [self persistentRootEditQueue: persistentRoot];
        }
        else
        {
            NSLog(@"requested UUID %@ not in store", aUUID);
        }
    }
    return root;
}

- (COPersistentRootEditQueue *) createPersistentRootWithInitialContents: (COObjectTree *)contents
                                                               metadata: (NSDictionary *)metadata
{
    id<COPersistentRootMetadata> persistentRoot = [store_ createPersistentRootWithInitialContents: contents metadata: metadata];
    
    return [self persistentRootEditQueue: persistentRoot];
}

- (COPersistentRootEditQueue *) createPersistentRootWithInitialRevision: (CORevisionID *)aRevision
                                                               metadata: (NSDictionary *)metadata
{
    id<COPersistentRootMetadata> persistentRoot = [store_ createPersistentRootWithInitialRevision: aRevision metadata: metadata];
    
    return [self persistentRootEditQueue: persistentRoot];
}


- (void) deletePersistentRootWithUUID: (COUUID *)aUUID
{
    [store_ deletePersistentRoot: aUUID];
}

@end

@implementation COStoreEditQueue (Private)

- (COSQLiteStore *)store
{
    return store_;
}

@end
