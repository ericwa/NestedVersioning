#import "TestCommon.h"


@interface TestSQLiteStore : NSObject <UKTest>
{
    COSQLiteStore *store;
}

@end


@implementation TestSQLiteStore

static const int NUM_CHILDREN = 1;
static const int NUM_COMMITS = 10000;
static const int NUM_PERSISTENT_ROOTS = 10;
static const int NUM_PERSISTENT_ROOT_COPIES = 100;

static COUUID *rootUUID;
static COUUID *childUUIDs[NUM_CHILDREN];

+ (void) initialize
{
    if (self == [TestSQLiteStore class])
    {
        rootUUID = [[COUUID alloc] init];
        for (int i=0; i<NUM_CHILDREN; i++)
        {
            childUUIDs[i] = [[COUUID alloc] init];
        }
    }
}

- (id) init
{
    self = [super init];
    
    [[NSFileManager defaultManager] removeItemAtPath: STOREPATH error: NULL];
    store = [[COSQLiteStore alloc] initWithURL: STOREURL];
    
    return self;
}

- (COItem *) initialRootItem
{
    COMutableItem *rootItem = [[[COMutableItem alloc] initWithUUID: rootUUID] autorelease];
    [rootItem setValue: @"root" forAttribute: @"name" type: [COType stringType]];
    [rootItem setValue: A()
          forAttribute: @"children"
                  type: [[COType embeddedItemType] arrayType]];
    
    for (int i=0; i<NUM_CHILDREN; i++)
    {
        [rootItem addObject: childUUIDs[i] forAttribute: @"children"];
    }
    return rootItem;
}

- (COItem *) initialChildItem: (int)i
{
    COMutableItem *child = [[[COMutableItem alloc] initWithUUID: childUUIDs[i]] autorelease];
    [child setValue: [self labelForCommit: 0 child: i]
       forAttribute: @"name"
               type: [COType stringType]];
    return child;
}

// returns index of the item that was changed at the given commit index
static int itemChangedAtCommit(int i)
{
    return ((1 + i) * 9871) % NUM_CHILDREN;
}

- (NSString *) labelForCommit: (int)commit // 0..(NUM_COMMITS - 1)
                        child: (int)child
{
    for (int i=commit; i>=0; i--)
    {
        if (itemChangedAtCommit(i) == child)
        {
            return [NSString stringWithFormat: @"modified %d in commit %d", child, i];
        }
    }
    return [NSString stringWithFormat: @"child %d never modified!", child];
}

#define RELOAD_ENTIRE_GRAPH_ON_EVERY_COMIT 0

#if 1
- (void)testBasic
{
//    for (int i=0; i<NUM_CHILDREN; i++)
//    {
//        NSLog(@"label: %@", [self labelForCommit: NUM_COMMITS - 1
//                                           child: i]);
//    }
    
    // Set up the initial items
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: NUM_CHILDREN+1];
    [dict setObject: [self initialRootItem] forKey: rootUUID];
    for (int i=0; i<NUM_CHILDREN; i++)
    {
        [dict setObject: [self initialChildItem: i]
                 forKey: childUUIDs[i]];
    }
    
    // Commit them to a persistet root
    
    COPersistentRootState *proot = [store createPersistentRootWithInitialContents: [[[COItemTree alloc] initWithItemForUUID: dict rootItemUUID: rootUUID] autorelease]
                                                                         metadata: nil
                                                                         isGCRoot: YES];
    
    // Commit a change to each object
    
    CORevisionID *lastCommitId = [[proot currentBranchState] currentState];
    for (int commit=1; commit<NUM_COMMITS; commit++)
    {
        int i = itemChangedAtCommit(commit);
        
        NSString *label = [self labelForCommit: commit child: i];
        
//        NSLog(@"item %d changed in commit %d - seting label to %@", i, commit, label);
        
        COMutableItem *item = [dict objectForKey: childUUIDs[i]];
        [item setValue:label
          forAttribute: @"name"];
        
        lastCommitId = [store writeItemTree: [[[COItemTree alloc] initWithItemForUUID: dict rootItemUUID: rootUUID] autorelease]
                               withMetadata: nil
                       withParentRevisionID: lastCommitId
                              modifiedItems: A(childUUIDs[i])];
    }
    
    // Now traverse them in reverse order and test that the items are as expected.
    // There are NUM_CHILDREN + 1 commits (the initial one made by creating the persistent roots)
#if RELOAD_ENTIRE_GRAPH_ON_EVERY_COMIT
    for (int rev=NUM_COMMITS-1; rev>=0; rev--)
    {
        COItemTree *tree = [store itemTreeForRevisionID: lastCommitId];

        // Check the state
        UKObjectsEqual(rootUUID, [tree rootItemUUID]);
        UKObjectsEqual([dict objectForKey: rootUUID],
                       [tree itemForUUID: rootUUID]);
        
        for (int i=0; i<NUM_CHILDREN; i++)
        {
            // on rev=NUM_CHILDREN, child[NUM_CHILDREN - 1]'s name was changed
            
            NSString *expectedLabel = [self labelForCommit: rev child: i];
            
            UKObjectsEqual(expectedLabel,
                           [[tree itemForUUID: childUUIDs[i]] valueForAttribute: @"name"]);
        }

        // Step back one revision
        
        lastCommitId = [[store revisionForID: lastCommitId] parentRevisionID];
    }
#elif 0
    for (int rev=NUM_COMMITS-1; rev>=1; rev--)
    {
        CORevisionID *parentCommitId = [[store revisionForID: lastCommitId] parentRevisionID];
        
        COItemTree *tree = [store partialItemTreeFromRevisionID: parentCommitId
                                                   toRevisionID: lastCommitId];
        
        int i = itemChangedAtCommit(rev);
        COItem *item = [tree itemForUUID: childUUIDs[i]];
        
        NSString *expectedLabel = [self labelForCommit: rev child: i];
        
        UKObjectsEqual(expectedLabel,
                       [item valueForAttribute: @"name"]);
              
        // Step back one revision
        
        lastCommitId = parentCommitId;
    }
#endif
    
    // Try search
    
    NSArray *results = [store revisionIDsMatchingQuery: @"\"modified 43 in commit 32\"'"];
    UKTrue([results count] == 1);
    if ([results count] == 1)
    {
        CORevisionID *revid = [results objectAtIndex: 0];
        UKObjectsEqual([lastCommitId backingStoreUUID], [revid backingStoreUUID]);
        UKIntsEqual(32, [revid revisionIndex]);
    }
    
    // Try walk commits
    
    [[store backingStoreForRevisionID: lastCommitId] benchmarkTableWalk];
}
#endif

- (COItemTree*) initialItemTree
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: NUM_CHILDREN+1];
    [dict setObject: [self initialRootItem] forKey: rootUUID];
    for (int i=0; i<NUM_CHILDREN; i++)
    {
        [dict setObject: [self initialChildItem: i]
                 forKey: childUUIDs[i]];
    }
    COItemTree *it = [[[COItemTree alloc] initWithItemForUUID: dict rootItemUUID: rootUUID] autorelease];
    return it;
}

- (void)testLotsOfPersistentRoots
{
    COItemTree *it = [self initialItemTree];
    
    for (int i =0; i<NUM_PERSISTENT_ROOTS; i++)
    {
        COPersistentRootState *proot = [store createPersistentRootWithInitialContents: it
                                                                             metadata: nil
                                                                             isGCRoot: YES];
    }
    UKPass();
}

- (void)testLotsOfPersistentRootCopies
{
    COItemTree *it = [self initialItemTree];

    COPersistentRootState *proot = [store createPersistentRootWithInitialContents: it
                                                                         metadata: nil
                                                                         isGCRoot: YES];
    
    for (int i =0; i<NUM_PERSISTENT_ROOT_COPIES; i++)
    {
        [store createPersistentRootWithInitialRevision: [[proot currentBranchState] currentState]
                                              metadata: nil
                                              isGCRoot: YES];
    }
    UKPass();
}

@end
