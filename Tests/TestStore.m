#import "TestCommon.h"

@interface TestStore : NSObject <UKTest> {
	
}

@end


@implementation TestStore

- (void) testTokenInMemory
{
    COUUID *aUUID = [COUUID UUID];
    
    COPersistentRootStateToken *t = [[COPersistentRootStateToken alloc] initWithProotCache: aUUID index: 1];
    
    UKObjectsEqual(t, [COPersistentRootStateToken tokenWithPlist: [t plist]]);    
}

static COSubtree *makeTree(NSString *message)
{
	COSubtree *t1 = [COSubtree subtree];
    [t1 setPrimitiveValue: message
             forAttribute: @"name"
                     type: [COType stringType]];
	COSubtree *t2 = [COSubtree subtree];
	COSubtree *t3 = [COSubtree subtree];
	[t1 addTree: t2];
	[t2 addTree: t3];
	return t1;
}

- (COPersistentRootStateToken *) currentState: (id<COPersistentRoot>)aRoot
{
    return [aRoot currentStateForBranch: [aRoot currentBranchUUID]];
}

- (void) testBasic
{
	COStore *store = setupStore();
	COSubtree *basicTree = makeTree(@"hello world");
    
    COPersistentRootState *state = [COPersistentRootState stateWithTree: basicTree];
    COUUID *prootUUID = [COUUID UUID];
    [store createPersistentRootWithUUID: prootUUID
                        initialContents: state];
    id<COPersistentRoot> proot = [store persistentRootWithUUID: prootUUID];
    
    UKObjectsEqual([NSArray arrayWithObject: [proot UUID]], [store allPersistentRootUUIDs]);
 
    // make a second commit
    
	COSubtree *basicTree2 = makeTree(@"hello world2");
    
    COPersistentRootState *state2 = [COPersistentRootState stateWithTree: basicTree2];
    COPersistentRootStateToken *token2 = [store addState: state2 parentState: [self currentState: proot]];
    
    [store setCurrentVersion: token2 forBranch: [proot currentBranchUUID] ofPersistentRoot: [proot UUID]];
    
    id<COPersistentRoot> prootFetched = [store persistentRootWithUUID: [proot UUID]];
    UKObjectsEqual(state2, [store fullStateForToken: [self currentState: prootFetched]]);
    UKObjectsNotEqual(state, [store fullStateForToken: [self currentState: prootFetched]]);
}
//
//- (void) testWithEditingContext
//{
//	COStore *store = setupStore();
//	COSubtree *basicTree = makeTree(@"hello world");
//    
//    // FIXME: Move support for this to editing context
//    
//    COPersistentRootState *state = [COPersistentRootState stateWithTree: basicTree];
//    COPersistentRoot *proot = [store createPersistentRootWithInitialContents: state];
//    
//    COPersistentRootEditingContext *ctx = [COPersistentRootEditingContext contextForEditingPersistentRootWithUUID: [proot UUID]
//                                                                                                          inStore: store];
//
//    UKObjectsEqual(basicTree, [ctx persistentRootTree]);
//    
//    // make a second commit
//    
//    [[ctx persistentRootTree] setValue: @"changed with context" forAttribute: @"name" type: [COType stringType]];
//
//    [ctx commitWithMetadata: nil];
//    
//    UKObjectsEqual(@"changed with context", [[[store fullStateForPersistentRootWithUUID: [ctx UUID]] tree] valueForAttribute: @"name"]);
//}

- (void)testReopenStore
{
	COUUID *prootUUID = nil;
    
    COPersistentRootState *state = [COPersistentRootState stateWithTree: makeTree(@"hello world")];
    
	{
        COStore *s = [[COStore alloc] initWithURL: STOREURL];
        
        prootUUID = [COUUID UUID];
        [s createPersistentRootWithUUID: prootUUID
                            initialContents: state];
        id<COPersistentRoot> proot = [s persistentRootWithUUID: prootUUID];
        [s release];
    }
    
    {
        COStore *s = [[COStore alloc] initWithURL: STOREURL];
        id<COPersistentRoot> prootFetched = [s persistentRootWithUUID: prootUUID];
        UKObjectsEqual(state, [s fullStateForToken: [self currentState: prootFetched]]);
        [s release];
    }
	
	[[NSFileManager defaultManager] removeItemAtPath: STOREPATH error: NULL];
}

- (void)testDeletePersistentRoot
{
	COStore *store = setupStore();
	COSubtree *basicTree = makeTree(@"hello world");
    
    COPersistentRootState *state = [COPersistentRootState stateWithTree: basicTree];
    
    COUUID *uuid = [COUUID UUID];
    [store createPersistentRootWithUUID: uuid
                        initialContents: state];
    id<COPersistentRoot> proot = [store persistentRootWithUUID: uuid];
    
    UKObjectsEqual([NSArray arrayWithObject: uuid], [store allPersistentRootUUIDs]);
    
    [store deletePersistentRoot: uuid];
    
    UKObjectsEqual([NSArray array], [store allPersistentRootUUIDs]);
}

//- (void)testBranch
//{
//	// create a persistent root r with 3 branches: a, b, c; current branch: a
//	
//    COStore *store = setupStore();
//    // N.B. these commit immediately.
//    COPersistentRootState *state = [COPersistentRootState stateWithTree: makeTree(@"hello world")];
//    COPersistentRootState *state2 = [COPersistentRootState stateWithTree: makeTree(@"hello world2")];
//    COPersistentRootState *state3 = [COPersistentRootState stateWithTree: makeTree(@"hello world3")];
//    
//    COPersistentRoot *proot = [store createPersistentRootWithInitialContents: state];
//    COUUID *prootuuid = [proot UUID];
//    COPersistentRootStateToken *token = [self currentState: proot];
//    COPersistentRootStateToken *token2 = [store addState: state2 parentState: token];
//    COPersistentRootStateToken *token3 = [store addState: state3 parentState: token];
//    
//    COBranch *branch = [proot currentBranch];
//    COUUID *branch2uuid = [store createCopyOfBranch: [branch UUID] ofPersistentRoot: prootuuid];    
//    COUUID *branch3uuid = [store createCopyOfBranch: [branch UUID] ofPersistentRoot: prootuuid];
//
//    proot = [store persistentRootWithUUID: prootuuid];
//    COBranch *branch2 = [proot branchForUUID: branch2uuid];
//    COBranch *branch3 = [proot branchForUUID: branch3uuid];
//    
//    UKObjectsEqual(branch2uuid, [branch2 UUID]);
//    UKObjectsEqual(branch3uuid, [branch3 UUID]);
//    
//    UKObjectsEqual(S(branch, branch2, branch3), [NSSet setWithArray: [[store persistentRootWithUUID: prootuuid] branches]]);
//    
//    [store setCurrentBranch: branch2uuid forPersistentRoot: prootuuid];
//    
//    UKObjectsEqual(branch2uuid, [[[store persistentRootWithUUID: prootuuid] currentBranch] UUID]);
//    UKObjectsEqual(state, [store fullStateForPersistentRootWithUUID: prootuuid]);
//    
//    [store setCurrentVersion: token2 forBranch: branch2uuid ofPersistentRoot: prootuuid];
//    
//    UKObjectsEqual(state2, [store fullStateForPersistentRootWithUUID: prootuuid]);
//    
//    [store setCurrentVersion: token3 forBranch: branch3uuid ofPersistentRoot: prootuuid];
//    
//    UKObjectsEqual(state2, [store fullStateForPersistentRootWithUUID: prootuuid]);
//    UKObjectsEqual(state2, [store fullStateForPersistentRootWithUUID: prootuuid branchUUID: branch2uuid]);
//    UKObjectsEqual(state3, [store fullStateForPersistentRootWithUUID: prootuuid branchUUID: branch3uuid]);
//
//    // =========
//    // test undo
//    // =========
//    
//    UKFalse([store canRedoForPersistentRootWithUUID: prootuuid]);
//    
//    [store undoForPersistentRootWithUUID: prootuuid]; // undo branch3 (state -> state3)
//    
//    UKObjectsEqual(state2, [store fullStateForPersistentRootWithUUID: prootuuid]);
//    UKObjectsEqual(state2, [store fullStateForPersistentRootWithUUID: prootuuid branchUUID: branch2uuid]);
//    UKObjectsEqual(state, [store fullStateForPersistentRootWithUUID: prootuuid branchUUID: branch3uuid]);
//    
//    [store undoForPersistentRootWithUUID: prootuuid]; // undo branch2 (state -> state2)
//    
//    UKObjectsEqual(state, [store fullStateForPersistentRootWithUUID: prootuuid]);
//    UKObjectsEqual(state, [store fullStateForPersistentRootWithUUID: prootuuid branchUUID: branch2uuid]);
//    UKObjectsEqual(state, [store fullStateForPersistentRootWithUUID: prootuuid branchUUID: branch3uuid]);
//    
//    [store undoForPersistentRootWithUUID: prootuuid]; // undo switch current branch (branch -> branch2)
//    
//    UKObjectsEqual(state, [store fullStateForPersistentRootWithUUID: prootuuid]);
//    UKObjectsEqual([branch UUID], [[[store persistentRootWithUUID: prootuuid] currentBranch] UUID]);
//    
//    [store undoForPersistentRootWithUUID: prootuuid]; // undo creation of branch3
//    
//    UKIntsEqual(2, [[[store persistentRootWithUUID: prootuuid] branches] count]);
//    
//    [store undoForPersistentRootWithUUID: prootuuid]; // undo creation of branch2
//    
//    UKObjectsEqual(S(branch), [NSSet setWithArray: [[store persistentRootWithUUID: prootuuid] branches]]);
//    
//    UKFalse([store canUndoForPersistentRootWithUUID: prootuuid]);
//    
//    // =========
//    // test redo
//    // =========
//    
//    [store redoForPersistentRootWithUUID: prootuuid]; // redo creation of branch2
//    
//    UKIntsEqual(2, [[[store persistentRootWithUUID: prootuuid] branches] count]);
//    
//    [store redoForPersistentRootWithUUID: prootuuid]; // redo creation of branch3
//
//    UKIntsEqual(3, [[[store persistentRootWithUUID: prootuuid] branches] count]);
//    UKObjectsEqual(state, [store fullStateForPersistentRootWithUUID: prootuuid branchUUID: branch2uuid]);
//    UKObjectsEqual(state, [store fullStateForPersistentRootWithUUID: prootuuid branchUUID: branch3uuid]);
//
//    [store redoForPersistentRootWithUUID: prootuuid]; // redo switch current branch (branch -> branch2)  
//    
//    UKObjectsEqual(branch2uuid, [[[store persistentRootWithUUID: prootuuid] currentBranch] UUID]);
//    
//    [store redoForPersistentRootWithUUID: prootuuid]; // redo branch2 (state -> state2)
//    
//    UKObjectsEqual(state2, [store fullStateForPersistentRootWithUUID: prootuuid branchUUID: branch2uuid]);
//    UKObjectsEqual(state, [store fullStateForPersistentRootWithUUID: prootuuid branchUUID: branch3uuid]);
//    
//    [store redoForPersistentRootWithUUID: prootuuid]; // redo branch3 (state -> state3)
//    
//    UKObjectsEqual(state2, [store fullStateForPersistentRootWithUUID: prootuuid branchUUID: branch2uuid]);
//    UKObjectsEqual(state3, [store fullStateForPersistentRootWithUUID: prootuuid branchUUID: branch3uuid]);
//    UKFalse([store canRedoForPersistentRootWithUUID: prootuuid]);
//}

//- (void)testCopyPersistentRoot
//{
//	COStore *store = setupStore();
//
//    COPersistentRootState *state = [COPersistentRootState stateWithTree: makeTree(@"hello world")];
//    COPersistentRootState *state2 = [COPersistentRootState stateWithTree: makeTree(@"hello world2")];
//    UKObjectsNotEqual(state, state2);
//    
//    COPersistentRoot *proot = [store createPersistentRootWithInitialContents: state];
//    COPersistentRoot *proot2 = [store createCopyOfPersistentRoot: [proot UUID]];
//    
//    UKObjectsNotEqual([proot UUID], [proot2 UUID]);
//    
//    UKObjectsEqual(state, [store fullStateForPersistentRootWithUUID: [proot UUID]]);
//    UKObjectsEqual(state, [store fullStateForPersistentRootWithUUID: [proot2 UUID]]);
//    
//    // change proot2, verify that it didn't change proot
//    
//    COPersistentRootStateToken *token = [[proot currentBranch] currentState];
//    COPersistentRootStateToken *token2 = [store addState: state2 parentState: token];
//    
//    [store setCurrentVersion: token2 forBranch: [[proot2 currentBranch] UUID] ofPersistentRoot: [proot2 UUID]];
//    
//    UKObjectsEqual(state, [store fullStateForPersistentRootWithUUID: [proot UUID]]);
//    UKObjectsEqual(state2, [store fullStateForPersistentRootWithUUID: [proot2 UUID]]);
//}


- (void) testEditQueueApis
{
    COStoreEditQueue *store = [[COStoreEditQueue alloc] initWithURL: STOREURL];
    
    COPersistentRootEditQueue *proot = [store createPersistentRoot];

    COBranchEditQueue *currentBranch = [proot contextForEditingCurrentBranch];
    
    COUUID *initialBranchUUID = [currentBranch UUID];
    
    UKIntsEqual(1, [[proot branchUUIDs] count]);
    UKObjectsEqual([[proot branchUUIDs] objectAtIndex: 0], [currentBranch UUID]);
    
    // Verify that the new persistent root wasn't saved to the store yet.
    UKTrue([[store allPersistentRootUUIDs] count] == 0);
    
    [proot setName: @"my root"];
    [proot commitChanges];
    
    UKTrue([[store allPersistentRootUUIDs] count] == 1);
    
    COBranchEditQueue *newBranch = [proot createBranch];
    COUUID *newBranchUUID = [newBranch UUID];
    
    // Check that the currentBranch context is updated
    // if we switch branch
    
    [proot setCurrentBranchUUID: newBranchUUID];
    
    UKObjectsEqual(newBranchUUID, [currentBranch UUID]);
    
    // FIXME: Test:
    /*
    * It's going to be a bit of work to handle the case where
    * there is this context open on a particular branch,
    * as well as the explicit one created by -contextForEditingBranchWithUUID
    * because they should stay in sync?
    */
    
    // Close
    
    [[NSFileManager defaultManager] removeItemAtPath: STOREPATH error: NULL];
}

@end
