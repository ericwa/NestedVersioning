#import "TestCommon.h"


@interface TestStoreEditQueue : NSObject <UKTest> {
    COStore *store;
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
    store = [[COStore alloc] initWithURL: [NSURL fileURLWithPath: STOREPATH]];
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
    COPersistentRoot *proot = [store createPersistentRootWithInitialContents: [makeTree(@"root") objectTree]
                                                                             metadata: [NSDictionary dictionary]];
    
    // Verify that the new persistent root is saved
    UKIntsEqual(1, [[store allPersistentRootUUIDs] count]);
    
    COBranch *currentBranch = [proot contextForEditingCurrentBranch];
    CORevisionID *firstRevision = [currentBranch currentState];
    COItemTree *firstState = [[currentBranch editingContext] objectTree];
    COUUID *initialBranchUUID = [currentBranch UUID];
    
    UKIntsEqual(1, [[proot branchUUIDs] count]);
    UKObjectsEqual([[proot branchUUIDs] objectAtIndex: 0], [currentBranch UUID]);
    
    [proot setName: @"my root"];
    
    // Create a new branch and switch to it.
    
    COBranch *newBranch = [proot createBranchAtRevision: [[proot contextForEditingCurrentBranch] currentState]
                                                      setCurrent: YES];
    COUUID *newBranchUUID = [newBranch UUID];
    
    UKObjectsEqual(@"root", [[[newBranch editingContext] rootObject] valueForAttribute: @"label"]);
    UKFalse([newBranch hasChanges]);
    
    // Commit a change to the new branch.
    
    [[[newBranch editingContext] rootObject] addTree: makeTree(@"pizza")];
    UKTrue([newBranch hasChanges]);
    
    [newBranch commitChangesWithMetadata: [NSDictionary dictionary]];
    UKFalse([newBranch hasChanges]);
    CORevisionID *secondRevision = [newBranch currentState];
    COItemTree *secondTree = [[newBranch editingContext] objectTree];
    
    UKObjectsNotEqual(firstRevision, secondRevision);
    UKObjectsNotEqual(firstState, secondTree);
    
    // Check that the currentBranch context is updated
    // if we switch branch
    
    UKObjectsEqual(newBranchUUID, [currentBranch UUID]);

    
}

@end
