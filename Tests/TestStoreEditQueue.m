#import "TestCommon.h"


@interface TestStoreEditQueue : NSObject <UKTest> {
    COStoreEditQueue *store;
}

@end


@implementation TestStoreEditQueue

static COObject *makeTree(NSString *label)
{
    COEditingContext *ctx = [[[COEditingContext alloc] init] autorelease];
    [[ctx rootObject] setValue: label
                  forAttribute: @"label"
                          type: [COType stringType]];
    return [ctx rootObject];
}

- (id) init
{
    self = [super init];
    
    [[NSFileManager defaultManager] removeItemAtPath: STOREPATH error: NULL];
    store = [[COStoreEditQueue alloc] initWithURL: [NSURL fileURLWithPath: STOREPATH]];
    return self;
}

- (void) dealloc
{
    [[NSFileManager defaultManager] removeItemAtPath: STOREPATH error: NULL];
    [store release];
    [super dealloc];
}

- (void) testEditQueueApis
{
    COPersistentRootEditQueue *proot = [store createPersistentRootWithInitialContents: [makeTree(@"root") objectTree]
                                                                             metadata: [NSDictionary dictionary]];
    
    // Verify that the new persistent root is saved
    UKIntsEqual(1, [[store allPersistentRootUUIDs] count]);
    
    COBranchEditQueue *currentBranch = [proot contextForEditingCurrentBranch];
    
    COUUID *initialBranchUUID = [currentBranch UUID];
    
    UKIntsEqual(1, [[proot branchUUIDs] count]);
    UKObjectsEqual([[proot branchUUIDs] objectAtIndex: 0], [currentBranch UUID]);
    
    [proot setName: @"my root"];
    
    COBranchEditQueue *newBranch = [proot createBranchAtRevision: [[proot contextForEditingCurrentBranch] currentState]
                                                      setCurrent: YES];
    COUUID *newBranchUUID = [newBranch UUID];
    
    // Check that the currentBranch context is updated
    // if we switch branch
    
    //UKObjectsEqual(newBranchUUID, [currentBranch UUID]);
    
    // FIXME: Test:
    /*
     * It's going to be a bit of work to handle the case where
     * there is this context open on a particular branch,
     * as well as the explicit one created by -contextForEditingBranchWithUUID
     * because they should stay in sync?
     */
    
}

@end
