#import "TestCommon.h"


@interface TestSQLiteStore : NSObject <UKTest>
{
    COSQLiteStore *store;
}

@end


@implementation TestSQLiteStore

static const int NUM_CHILDREN = 1000;

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

- (COItemTree *) initialContents
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity: NUM_CHILDREN];
    
    COMutableItem *rootItem = [[[COMutableItem alloc] initWithUUID: rootUUID] autorelease];
    [rootItem setValue: @"root" forAttribute: @"name" type: [COType stringType]];
    [rootItem setValue: A()
          forAttribute: @"children"
                  type: [COType uniqueArrayWithPrimitiveType: [COType embeddedItemType]]];
    [items addObject: rootItem];
    
    for (int i=0; i<NUM_CHILDREN; i++)
    {
        COMutableItem *child = [[[COMutableItem alloc] initWithUUID: childUUIDs[i]] autorelease];
        [child setValue: [NSString stringWithFormat: @"child %d", i]
           forAttribute: @"name"
                   type: [COType stringType]];
        [rootItem addObject: [child UUID] forAttribute: @"children"];
        [items addObject: child];
    }
    
    return [COItemTree itemTreeWithItems: items
                            rootItemUUID: rootUUID];
}

- (void)testBasic
{
    COItemTree *initialContents = [self initialContents];
    COPersistentRootState *state = [store createPersistentRootWithInitialContents: initialContents
                                                                         metadata: nil
                                                                         isGCRoot: YES];
    
    COItemTree *readBack = [store itemTreeForRevisionID: [[state currentBranchState] currentState]];
    
    UKObjectsEqual(initialContents, readBack);
}

@end
