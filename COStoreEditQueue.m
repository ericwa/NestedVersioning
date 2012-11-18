#import "COStoreEditQueue.h"
#import "COMacros.h"
#import "COEditQueuePrivate.h"

@implementation COStoreEditQueue

- (id)initWithURL: (NSURL*)aURL
{
    SUPERINIT;
    store_ = [[COStore alloc] initWithURL: aURL];
    rootForUUID_ = [[NSMutableDictionary alloc] init];
    return self;
}

- (void)dealoc
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

- (COPersistentRootEditQueue *) persistentRootWithUUID: (COUUID *)aUUID
{
    COPersistentRootEditQueue *root = [rootForUUID_ objectForKey: aUUID];
    if (root == nil)
    {
        if ([[self allPersistentRootUUIDs] containsObject: aUUID])
        {
            root = [[COPersistentRootEditQueue alloc] initWithRootStore: self uuid: aUUID isNew: NO];
            [rootForUUID_ setObject: root forKey: aUUID];
            [root release];
        }
        else
        {
            NSLog(@"requested UUID %@ not in store", aUUID);
        }
    }
    return root;
}

- (COPersistentRootEditQueue *) createPersistentRoot
{
    COUUID *newUUID = [COUUID UUID];
    COPersistentRootEditQueue *proot = [[COPersistentRootEditQueue alloc] initWithRootStore: self uuid: newUUID isNew: YES];
    
    [rootForUUID_ setObject: proot forKey: newUUID];
    return proot;
}

- (void) deletePersistentRootWithUUID: (COUUID *)aUUID
{
    [store_ deletePersistentRoot: aUUID];
}

@end

@implementation COStoreEditQueue (Private)

- (COStore *)store
{
    return store_;
}

@end
