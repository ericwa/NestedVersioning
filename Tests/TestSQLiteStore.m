#import "TestCommon.h"


@interface TestSQLiteStore : NSObject <UKTest>
{
    COSQLiteStore *store;
}

@end


@implementation TestSQLiteStore

static const int NUM_CHILDREN = 400;

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

- (COMutableItem *) initialRootItem
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

- (NSMutableArray *) initialChildItems
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity: NUM_CHILDREN];
    
    for (int i=0; i<NUM_CHILDREN; i++)
    {
        COMutableItem *child = [[[COMutableItem alloc] initWithUUID: childUUIDs[i]] autorelease];
        [child setValue: [NSString stringWithFormat: @"child %d", i]
           forAttribute: @"name"
                   type: [COType stringType]];

        [items addObject: [[child copy] autorelease]];
    }
    
    return items;
}

- (COItemTree *) initialContents
{
    return [COItemTree itemTreeWithItems: [[self initialChildItems] arrayByAddingObject: [self initialRootItem]]
                                   rootItemUUID: rootUUID];
}

- (COItemTree *) modifiedContents: (int)i
{
    COMutableItem *initialRootItem = [self initialRootItem];
    NSMutableArray *initialChildItems = [self initialChildItems];
    
    for (int j=0; j<=i; j++)
    {
        COMutableItem *mi = [[[initialChildItems objectAtIndex: j] mutableCopy] autorelease];
        [mi setValue: [NSString stringWithFormat: @"edited %d", j]
        forAttribute: @"name"
                type: [COType stringType]];
        [initialChildItems replaceObjectAtIndex: j
                                     withObject: [[mi copy]autorelease]];
    }

    COItemTree *modifiedContents = [COItemTree
                                    itemTreeWithItems: [initialChildItems arrayByAddingObject: initialRootItem]
                                    rootItemUUID: rootUUID];
    return modifiedContents;
}

- (void)testBasic
{
    COPersistentRootState *proot = [store createPersistentRootWithInitialContents: [self initialContents]
                                                                         metadata: nil
                                                                         isGCRoot: YES];
    
    // Test reading back the first commit
    
    COItemTree *readBack = [store itemTreeForRevisionID: [[proot currentBranchState] currentState]];
    UKObjectsEqual([self initialContents], readBack);
    
    // Commit a change to each object
    
    CORevisionID *lastCommitId = [[proot currentBranchState] currentState];
    for (int i=0; i<NUM_CHILDREN; i++)
    {
        lastCommitId = [store writeItemTree: [self modifiedContents: i]
                               withMetadata: nil
                       withParentRevisionID: lastCommitId
                              modifiedItems: A(childUUIDs[i])];
    }
    
    
    // Now traverse them in reverse order
    
    for (int i=NUM_CHILDREN-1; i>=0; i--)
    {
        UKObjectsEqual([self modifiedContents: i], [store itemTreeForRevisionID: lastCommitId]);
        lastCommitId = [[store revisionForID: lastCommitId] parentRevisionID];
    }
}

@end
