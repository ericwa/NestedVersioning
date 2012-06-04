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

- (void) testBranchInMemory
{
    COUUID *aUUID = [COUUID UUID];

    COUUID *stateUUID = [COUUID UUID];    
    COPersistentRootStateToken *token = [[COPersistentRootStateToken alloc] initWithProotCache: stateUUID index: 1];

    
    COBranch *branch = [[COBranch alloc] initWithUUID: aUUID
                                                 name: @"hello"
                                         initialState: token
                                             metadata: @"meta"];
    id plist = [branch _plist];
    COBranch *branchCopy = [COBranch _branchWithPlist: plist];
    
    UKObjectsEqual(branch, branchCopy);
}

- (void) testPersistentRootInMemory
{
    COUUID *prootUUID = [COUUID UUID];
    COUUID *branchUUID = [COUUID UUID];
    
    COUUID *stateUUID = [COUUID UUID];
    COPersistentRootStateToken *token = [[COPersistentRootStateToken alloc] initWithProotCache: stateUUID index: 1];
    
    
    COBranch *branch = [[COBranch alloc] initWithUUID: branchUUID
                                                 name: @"hello"
                                         initialState: token
                                             metadata: @"meta"];
  
    COPersistentRoot *proot = [[COPersistentRoot alloc] initWithUUID: prootUUID
                                                          branches: [NSArray arrayWithObject: branch]
                                                     currentBranch: [branch UUID]
                                                          metadata: nil];
    
    COPersistentRoot *prootCopy = [[COPersistentRoot alloc] initWithPlist: [proot plist]];
    
    UKObjectsEqual(proot, prootCopy);
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

- (void) testBasic
{
	COStore *store = setupStore();
	COSubtree *basicTree = makeTree(@"hello world");
    
    COPersistentRootState *state = [COPersistentRootState stateWithTree: basicTree];
    COPersistentRoot *proot = [store createPersistentRootWithInitialContents: state];
    
    UKObjectsEqual([NSArray arrayWithObject: [proot UUID]], [store allPersistentRootUUIDs]);
 
    // make a second commit
    
	COSubtree *basicTree2 = makeTree(@"hello world2");
    
    COPersistentRootState *state2 = [COPersistentRootState stateWithTree: basicTree2];
    COPersistentRootStateToken *token2 = [store addState: state2 parentState: [[proot currentBranch] currentState]];
    
    [store setCurrentVersion: token2 forBranch: [[proot currentBranch] UUID] ofPersistentRoot: [proot UUID]];
    
    COPersistentRoot *prootFetched = [store persistentRootWithUUID: [proot UUID]];
    UKObjectsEqual(state2, [store fullStateForToken: [[prootFetched currentBranch] currentState]]);
    UKObjectsNotEqual(state, [store fullStateForToken: [[prootFetched currentBranch] currentState]]);
}

- (void)testReopenStore
{
	COUUID *prootUUID = nil;
    
    COPersistentRootState *state = [COPersistentRootState stateWithTree: makeTree(@"hello world")];
    
	{
        COStore *s = [[COStore alloc] initWithURL: STOREURL];             
        COPersistentRoot *proot = [s createPersistentRootWithInitialContents: state];
        prootUUID = [proot UUID];
        [s release];
    }
    
    {
        COStore *s = [[COStore alloc] initWithURL: STOREURL];
        COPersistentRoot *prootFetched = [s persistentRootWithUUID: prootUUID];
        UKObjectsEqual(state, [s fullStateForToken: [[prootFetched currentBranch] currentState]]);
        [s release];
    }
	
	[[NSFileManager defaultManager] removeItemAtPath: STOREPATH error: NULL];
}

- (void)testDeletePersistentRoot
{
	COStore *store = setupStore();
	COSubtree *basicTree = makeTree(@"hello world");
    
    COPersistentRootState *state = [COPersistentRootState stateWithTree: basicTree];
    COPersistentRoot *proot = [store createPersistentRootWithInitialContents: state];
    
    UKObjectsEqual([NSArray arrayWithObject: [proot UUID]], [store allPersistentRootUUIDs]);
    
    [store deletePersistentRoot: [proot UUID]];
    
    UKObjectsEqual([NSArray array], [store allPersistentRootUUIDs]);
}

- (void)testBranch
{
	// create a persistent root r with 3 branches: a, b, c; current branch: a
	
    COStore *store = setupStore();
    // N.B. these commit immediately.
    COPersistentRootState *state = [COPersistentRootState stateWithTree: makeTree(@"hello world")];
    COPersistentRootState *state2 = [COPersistentRootState stateWithTree: makeTree(@"hello world2")];
    COPersistentRootState *state3 = [COPersistentRootState stateWithTree: makeTree(@"hello world3")];
    
    COPersistentRoot *proot = [store createPersistentRootWithInitialContents: state];
    COUUID *prootuuid = [proot UUID];
    COPersistentRootStateToken *token = [[proot currentBranch] currentState];
    COPersistentRootStateToken *token2 = [store addState: state2 parentState: token];
    COPersistentRootStateToken *token3 = [store addState: state3 parentState: token];
    
    COBranch *branch = [proot currentBranch];
    COUUID *branch2uuid = [store createCopyOfBranch: [branch UUID] ofPersistentRoot: prootuuid];
    COUUID *branch3uuid = [store createCopyOfBranch: [branch UUID] ofPersistentRoot: prootuuid];

    proot = [store persistentRootWithUUID: prootuuid];
    COBranch *branch2 = [proot branchForUUID: branch2uuid];
    COBranch *branch3 = [proot branchForUUID: branch3uuid];
    
    UKObjectsEqual(S(branch, branch2, branch3), [NSSet setWithArray: [[store persistentRootWithUUID: prootuuid] branches]]);
    
    [store setCurrentVersion: token2 forBranch: branch2uuid ofPersistentRoot: prootuuid];
    [store setCurrentVersion: token3 forBranch: branch3uuid ofPersistentRoot: prootuuid];
    
    UKObjectsEqual(state2, [store fullStateForPersistentRootWithUUID: prootuuid branchUUID: branch2uuid]);
    UKObjectsEqual(state3, [store fullStateForPersistentRootWithUUID: prootuuid branchUUID: branch3uuid]);
}

- (void)testCopyPersistentRoot
{
	COStore *store = setupStore();

    COPersistentRootState *state = [COPersistentRootState stateWithTree: makeTree(@"hello world")];
    COPersistentRootState *state2 = [COPersistentRootState stateWithTree: makeTree(@"hello world2")];
    UKObjectsNotEqual(state, state2);
    
    COPersistentRoot *proot = [store createPersistentRootWithInitialContents: state];
    COPersistentRoot *proot2 = [store createCopyOfPersistentRoot: [proot UUID]];
    
    UKObjectsNotEqual([proot UUID], [proot2 UUID]);
    
    UKObjectsEqual(state, [store fullStateForPersistentRootWithUUID: [proot UUID]]);
    UKObjectsEqual(state, [store fullStateForPersistentRootWithUUID: [proot2 UUID]]);
    
    // change proot2, verify that it didn't change proot
    
    COPersistentRootStateToken *token = [[proot currentBranch] currentState];
    COPersistentRootStateToken *token2 = [store addState: state2 parentState: token];
    
    [store setCurrentVersion: token2 forBranch: [[proot2 currentBranch] UUID] ofPersistentRoot: [proot2 UUID]];
    
    UKObjectsEqual(state, [store fullStateForPersistentRootWithUUID: [proot UUID]]);
    UKObjectsEqual(state2, [store fullStateForPersistentRootWithUUID: [proot2 UUID]]);
}


@end
