#import "TestCommon.h"


@interface TestSQLiteStore : NSObject <UKTest>
{
    COSQLiteStore *store;
}

@end


@implementation TestSQLiteStore

static const int NUM_CHILDREN = 60;
static const int NUM_COMMITS = 100;

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
                  type: [COType uniqueArrayWithPrimitiveType: [COType embeddedItemType]]];
    
    for (int i=0; i<NUM_CHILDREN; i++)
    {
        [rootItem addObject: childUUIDs[i] forAttribute: @"children"];
    }
    return rootItem;
}

- (COItem *) childItem: (int)i withLabel: (NSString *)label
{
    COMutableItem *child = [[[COMutableItem alloc] initWithUUID: childUUIDs[i]] autorelease];
    [child setValue: label
       forAttribute: @"name"
               type: [COType stringType]];
    return child;
}

- (void)testBasic
{
    // Set up the initial items
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: NUM_CHILDREN+1];
    [dict setObject: [self initialRootItem] forKey: rootUUID];
    for (int i=0; i<NUM_CHILDREN; i++)
    {
        [dict setObject: [self childItem: i withLabel: [NSString stringWithFormat: @"child %d", i]]
                 forKey: childUUIDs[i]];
    }
    
    // Commit them to a persistet root
    
    COPersistentRootState *proot = [store createPersistentRootWithInitialContents: [[[COItemTree alloc] initWithItemForUUID: dict rootItemUUID: rootUUID] autorelease]
                                                                         metadata: nil
                                                                         isGCRoot: YES];
    
    // Commit a change to each object
    
    CORevisionID *lastCommitId = [[proot currentBranchState] currentState];
    for (int i=0; i<NUM_CHILDREN; i++)
    {        
        // Make a change to childUUIDs[i]
        
        COMutableItem *item = [dict objectForKey: childUUIDs[i]];
        [item setValue: [NSString stringWithFormat: @"modified child %d", i]
          forAttribute: @"name"];
        
        lastCommitId = [store writeItemTree: [[[COItemTree alloc] initWithItemForUUID: dict rootItemUUID: rootUUID] autorelease]
                               withMetadata: nil
                       withParentRevisionID: lastCommitId
                              modifiedItems: A(childUUIDs[i])];
    }
    
    // Now traverse them in reverse order and test that the items are as expected.
    // There are NUM_CHILDREN + 1 commits (the initial one made by creating the persistent roots)
    
    for (int rev=NUM_CHILDREN; rev>=0; rev--)
    {
        COItemTree *tree = [store itemTreeForRevisionID: lastCommitId];

        // Check the state
        
        UKObjectsEqual(rootUUID, [tree rootItemUUID]);
        UKObjectsEqual([dict objectForKey: rootUUID],
                       [tree itemForUUID: rootUUID]);
        for (int i=0; i<NUM_CHILDREN; i++)
        {
            // on rev=NUM_CHILDREN, child[NUM_CHILDREN - 1]'s name was changed
            
            NSString *expectedLabel = (i < rev)
                ? [NSString stringWithFormat: @"modified child %d", i]
                : [NSString stringWithFormat: @"child %d", i];
            
            UKObjectsEqual(expectedLabel,
                           [[tree itemForUUID: childUUIDs[i]] valueForAttribute: @"name"]);
        }

        // Step back one revision
        
        lastCommitId = [[store revisionForID: lastCommitId] parentRevisionID];
    }
}

@end
