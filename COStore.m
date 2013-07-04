#import "COStore.h"
#import <EtoileFoundation/Macros.h>
#import "COPersistentRootPrivate.h"
#import "COSQLiteStore.h"

@implementation COStore

- (id)initWithURL: (NSURL*)aURL
{
    SUPERINIT;
    store_ = [[COSQLiteStore alloc] initWithURL: aURL];
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

- (void) fetchPersistentRoots
{
    if (rootForUUID_ == nil)
    {
        rootForUUID_ = [[NSMutableDictionary alloc] init];
        for (COUUID *uuid in [store_ persistentRootUUIDs])
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

- (COPersistentRoot *) createPersistentRootWithInitialContents: (COEditingContext *)contents
                                                      metadata: (NSDictionary *)metadata
{
    COPersistentRootState *persistentRoot = [store_ createPersistentRootWithInitialContents: contents metadata: metadata];
    
    return [self cachePersistentRootEditPlist: persistentRoot];
}

- (COPersistentRoot *) createPersistentRootWithInitialRevision: (CORevisionID *)aRevision
                                                      metadata: (NSDictionary *)metadata
{
    COPersistentRootState *persistentRoot = [store_ createPersistentRootWithInitialRevision: aRevision metadata: metadata ];
    
    return [self cachePersistentRootEditPlist: persistentRoot];
}


- (void) deletePersistentRootWithUUID: (COUUID *)aUUID
{
    [self fetchPersistentRoots];
    [store_ deletePersistentRoot: aUUID];
    [rootForUUID_ removeObjectForKey: aUUID];
}

@end

@implementation COStore (Private)

- (COSQLiteStore *)store
{
    return store_;
}

@end
