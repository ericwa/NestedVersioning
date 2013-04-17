#import "TestCommon.h"

/**
 * For each execution of a test method, the store is recreated and a persistent root
 * is created in -init with a single commit, with the contents returned by -makeInitialItemTree.
 */
@interface TestSQLiteStore : COSQLiteStoreTestCase <UKTest>
{
    COPersistentRootState *proot;
    COUUID *prootUUID;
    COUUID *initialBranchUUID;
    CORevisionID *initialRevisionId;
}
@end

@implementation TestSQLiteStore

static COUUID *rootUUID;
static COUUID *childUUID;

+ (void) initialize
{
    if (self == [TestSQLiteStore class])
    {
        rootUUID = [[COUUID alloc] init];
        childUUID = [[COUUID alloc] init];
    }
}

// --- Example data setup

- (COItem *) initialRootItem
{
    COMutableItem *rootItem = [[[COMutableItem alloc] initWithUUID: rootUUID] autorelease];
    [rootItem setValue: @"root" forAttribute: @"name" type: kCOStringType];
    [rootItem setValue: A(childUUID)
          forAttribute: @"children"
                  type: kCOEmbeddedItemType | kCOArrayType];
    return rootItem;
}

- (COItem *) initialChildItem
{
    COMutableItem *child = [[[COMutableItem alloc] initWithUUID: childUUID] autorelease];
    [child setValue: @"child"
       forAttribute: @"name"
               type: kCOStringType];
    return child;
}

- (COItemTree*) makeInitialItemTree
{
    return [[[COItemTree alloc] initWithItemForUUID: D([self initialRootItem], rootUUID,
                                                       [self initialChildItem], childUUID)
                                       rootItemUUID: rootUUID] autorelease];
}

- (COItemTree *)itemTreeWithChildNameChange: (NSString*)aName
{
    COItemTree *it = [self makeInitialItemTree];    
    COMutableItem *item = (COMutableItem *)[it itemForUUID: childUUID];
    [item setValue: aName
      forAttribute: @"name"];
    return it;
}

- (CORevisionID *)commitChildNameChange: (NSString*)aName
                              parentRev: (CORevisionID *)aParent
{
    return [store writeItemTree: [self itemTreeWithChildNameChange: aName]
                   withMetadata: nil
           withParentRevisionID: aParent
                  modifiedItems: A(childUUID)];
}

- (id) init
{
    SUPERINIT;
    COItemTree *it = [self makeInitialItemTree];
    ASSIGN(proot, [store createPersistentRootWithInitialContents: it
                                                        metadata: D(@"test1", @"name")]);
    ASSIGN(prootUUID, [proot UUID]);
    ASSIGN(initialBranchUUID, [proot currentBranchUUID]);
    ASSIGN(initialRevisionId, [[proot currentBranchState] currentState]);
    return self;
}

- (void) dealloc
{
    [proot release];
    [prootUUID release];
    [initialBranchUUID release];
    [initialRevisionId release];
    [super dealloc];
}


// --- The tests themselves

- (void) testDeleteBranch
{
    // Create it
    COUUID *branch = [store createBranchWithInitialRevision: [[proot currentBranchState] currentState]
                                                 setCurrent: YES
                                          forPersistentRoot: prootUUID];
    
    UKObjectKindOf(branch, COUUID);
    UKObjectsNotEqual(initialBranchUUID, branch);
    UKObjectsEqual(S(branch, initialBranchUUID), [[store persistentRootWithUUID: prootUUID] branchUUIDs]);
    
    // Delete it
    UKTrue([store deleteBranch: branch ofPersistentRoot: prootUUID]);
    
    {
        COBranchState *branchObj = [[store persistentRootWithUUID: prootUUID] branchPlistForUUID: branch];
        UKNotNil(branchObj);
        UKTrue([branchObj isDeleted]);
    }

    // Undelete it
    UKTrue([store undeleteBranch: branch ofPersistentRoot: prootUUID]);
    {
        COBranchState *branchObj = [[store persistentRootWithUUID: prootUUID] branchPlistForUUID: branch];
        UKNotNil(branchObj);
        UKFalse([branchObj isDeleted]);
    }
}


- (void) testBranchMetadata
{
    UKNil([[[store persistentRootWithUUID: prootUUID] currentBranchState] metadata]);
    
    UKTrue([store setMetadata: D(@"hello world", @"msg")
                    forBranch: initialBranchUUID
             ofPersistentRoot: prootUUID]);
    
    UKObjectsEqual(D(@"hello world", @"msg"), [[[store persistentRootWithUUID: prootUUID] currentBranchState] metadata]);
    
    UKTrue([store setMetadata: nil
                    forBranch: initialBranchUUID
             ofPersistentRoot: prootUUID]);
    
    UKNil([[[store persistentRootWithUUID: prootUUID] currentBranchState] metadata]);
}

- (void) testPersistentRootMetadata
{
    UKObjectsEqual(D(@"test1", @"name"), [[store persistentRootWithUUID: prootUUID] metadata]);
    
    UKTrue([store setMetadata: D(@"hello world", @"name")
            forPersistentRoot: prootUUID]);
    
    UKObjectsEqual(D(@"hello world", @"name"), [[store persistentRootWithUUID: prootUUID] metadata]);
    
    UKTrue([store setMetadata: nil
             forPersistentRoot: prootUUID]);
    
    UKNil([[store persistentRootWithUUID: prootUUID] metadata]);
}

- (void) testCrossPersistentRootReference
{
    
}

- (void) testAttachmentsGCDoesNotCollectReferenced
{
    NSString *fakeAttachment = @"this is a large attachment";
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent: @"cotest.txt"];
    
    UKTrue([fakeAttachment writeToFile: path
                            atomically: YES
                              encoding: NSUTF8StringEncoding
                                 error: NULL]);
    
    NSData *hash = [store addAttachmentAtURL: [NSURL fileURLWithPath: path]];
    UKNotNil(hash);
    
    NSString *internalPath = [[store URLForAttachment: hash] path];
    
    UKTrue([path hasPrefix: NSTemporaryDirectory()]);
    UKFalse([internalPath hasPrefix: NSTemporaryDirectory()]);
    
    NSLog(@"external path: %@", path);
    NSLog(@"internal path: %@", internalPath);
    
    UKObjectsEqual(fakeAttachment, [NSString stringWithContentsOfURL: [store URLForAttachment: hash]
                                                            encoding: NSUTF8StringEncoding
                                                               error: NULL]);
    
    // Test attachment GC
    
    COItemTree *tree = [self makeInitialItemTree];
    [[tree itemForUUID: childUUID] setValue: hash forAttribute: @"attachment" type: kCOAttachmentType];
    CORevisionID *withAttachment = [store writeItemTree: tree withMetadata: nil withParentRevisionID: initialRevisionId modifiedItems: nil];
    UKNotNil(withAttachment);
    UKTrue([store setCurrentVersion: withAttachment
                          forBranch: initialBranchUUID
                   ofPersistentRoot: prootUUID
                         updateHead: YES]);
    
    UKTrue([store finalizeDeletionsForPersistentRoot: prootUUID]);
    
    UKObjectsEqual(fakeAttachment, [NSString stringWithContentsOfURL: [store URLForAttachment: hash]
                                                            encoding: NSUTF8StringEncoding
                                                               error: NULL]);
}

- (void) testAttachmentsGCCollectsUnReferenced
{
    NSString *fakeAttachment = @"this is a large attachment";
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent: @"cotest.txt"];
    [fakeAttachment writeToFile: path
                     atomically: YES
                       encoding: NSUTF8StringEncoding
                          error: NULL];    
    NSData *hash = [store addAttachmentAtURL: [NSURL fileURLWithPath: path]];
    
    UKObjectsEqual(fakeAttachment, [NSString stringWithContentsOfURL: [store URLForAttachment: hash]
                                                            encoding: NSUTF8StringEncoding
                                                               error: NULL]);

    UKTrue([[NSFileManager defaultManager] fileExistsAtPath: [[store URLForAttachment: hash] path]]);
    UKTrue([store finalizeGarbageAttachments]);
    UKFalse([[NSFileManager defaultManager] fileExistsAtPath: [[store URLForAttachment: hash] path]]);
}

/**
 * See the conceptual model of the store in the COSQLiteStore comment. Revisions are not 
 * first class citizes; we garbage-collect them when they are not referenced.
 */
- (void) testRevisionGCDoesNotCollectReferenced
{
    COItemTree *tree = [self makeInitialItemTree];
    CORevisionID *referencedRevision = [store writeItemTree: tree
                                               withMetadata: nil
                                       withParentRevisionID: initialRevisionId
                                              modifiedItems: nil];
    
    UKTrue([store setCurrentVersion: referencedRevision
                          forBranch: initialBranchUUID
                   ofPersistentRoot: prootUUID
                         updateHead: YES]);
    
    UKTrue([store finalizeDeletionsForPersistentRoot: prootUUID]);
    
    UKObjectsEqual(tree, [store itemTreeForRevisionID: referencedRevision]);
}

- (void) testRevisionGCCollectsUnReferenced
{
    COItemTree *tree = [self makeInitialItemTree];
    CORevisionID *unreferencedRevision = [store writeItemTree: tree
                                                 withMetadata: nil
                                         withParentRevisionID: initialRevisionId
                                                modifiedItems: nil];
    
    UKObjectsEqual(tree, [store itemTreeForRevisionID: unreferencedRevision]);
    
    UKTrue([store finalizeDeletionsForPersistentRoot: prootUUID]);
    
    UKNil([store itemTreeForRevisionID: unreferencedRevision]);
}

- (void) testDeletePersistentRoot
{    
    UKTrue([store deletePersistentRoot: prootUUID]);
    // Persistent root returned since we have not called finalizeDeletions.
    UKObjectsEqual(A(prootUUID), [store persistentRootUUIDs]);
    
    // Persistent root returned since we have not called finalizeDeletions.
    UKNotNil([store persistentRootWithUUID: prootUUID]);
    
    UKTrue([store finalizeDeletionsForPersistentRoot: prootUUID]);
    
    UKObjectsEqual([NSArray array], [store persistentRootUUIDs]);
    UKNil([store persistentRootWithUUID: prootUUID]);    
}

- (void) testPersistentRootBasic
{
    UKObjectsEqual(S(prootUUID), [NSSet setWithArray:[store persistentRootUUIDs]]);
    UKObjectsEqual(initialBranchUUID, [[store persistentRootWithUUID: prootUUID] currentBranchUUID]);
    COPersistentRootState *refetched = [store persistentRootWithUUID: prootUUID];
    UKObjectsEqual(proot, refetched);
    UKObjectsEqual([self makeInitialItemTree], [store itemTreeForRevisionID: initialRevisionId]);
}

/**
 * Tests creating a persistent root, proot, making a copy of it, and then making a commit
 * to proot and a commit to the copy.
 */
- (void)testPersistentRootCopies
{
    COPersistentRootState *copy = [store createPersistentRootWithInitialRevision: initialRevisionId
                                                                        metadata: D(@"test2", @"name")];

    UKObjectsEqual(S(prootUUID, [copy UUID]), [NSSet setWithArray:[store persistentRootUUIDs]]);

    // 1. check setup
    
    // Verify that new UUIDs were generated
    UKObjectsNotEqual(prootUUID, [copy UUID]);
    UKObjectsNotEqual([proot branchUUIDs], [copy branchUUIDs]);
    
    // Make sure metadata was read out properly
    UKObjectsEqual(D(@"test2", @"name"), [copy metadata]);
    
    // Check that the current branch is set correctly
    UKObjectsEqual([[copy branchUUIDs] anyObject], [copy currentBranchUUID]);
    
    // Check that the branch data is the same
    UKNotNil([[proot currentBranchState] headRevisionID]);
    UKNotNil([[proot currentBranchState] tailRevisionID]);
    UKNotNil(initialRevisionId);
    UKObjectsEqual([[proot currentBranchState] headRevisionID], [[copy currentBranchState] headRevisionID]);
    UKObjectsEqual([[proot currentBranchState] tailRevisionID], [[copy currentBranchState] tailRevisionID]);
    UKObjectsEqual(initialRevisionId, [[copy currentBranchState] currentState]);
    
    // Make sure the persistent root state returned from createPersistentRoot matches what the store
    // gives us when we read it back.

    UKObjectsEqual(copy, [store persistentRootWithUUID: [copy UUID]]);
    
    // 2. try changing. Verify that proot and copy are totally independent
    
    CORevisionID *mod1 = [self commitChildNameChange: @"edit1"
                                           parentRev: initialRevisionId];
    
    CORevisionID *mod2 = [self commitChildNameChange: @"edit2"
                                           parentRev: initialRevisionId];
    

    UKObjectsEqual([self itemTreeWithChildNameChange: @"edit1"], [store itemTreeForRevisionID: mod1]);
    UKObjectsEqual([self itemTreeWithChildNameChange: @"edit2"], [store itemTreeForRevisionID: mod2]);

    UKTrue([store setCurrentVersion: mod1
                          forBranch: [[proot currentBranchState] UUID]
                   ofPersistentRoot: prootUUID
                         updateHead: YES]);
    
    // Reload proot's and copy's metadata
    
    ASSIGN(proot, [store persistentRootWithUUID: prootUUID]);
    copy = [store persistentRootWithUUID: [copy UUID]];
    UKObjectsEqual(mod1, [[proot currentBranchState] currentState]);
    UKObjectsEqual(mod1, [[proot currentBranchState] headRevisionID]);
    UKObjectsEqual(initialRevisionId, [[proot currentBranchState] tailRevisionID]);
    UKObjectsEqual(initialRevisionId, [[copy currentBranchState] currentState]);
    UKObjectsEqual(initialRevisionId, [[copy currentBranchState] headRevisionID]);
    UKObjectsEqual(initialRevisionId, [[copy currentBranchState] tailRevisionID]);
    
    // Commit to copy as well.
    
    UKTrue([store setCurrentVersion: mod2
                          forBranch: [[copy currentBranchState] UUID]
                   ofPersistentRoot: [copy UUID]
                         updateHead: YES]);
    
    // Reload proot's and copy's metadata
    
    ASSIGN(proot, [store persistentRootWithUUID: prootUUID]);
    copy = [store persistentRootWithUUID: [copy UUID]];
    UKObjectsEqual(mod1, [[proot currentBranchState] currentState]);
    UKObjectsEqual(mod1, [[proot currentBranchState] headRevisionID]);
    UKObjectsEqual(initialRevisionId, [[proot currentBranchState] tailRevisionID]);
    UKObjectsEqual(mod2, [[copy currentBranchState] currentState]);
    UKObjectsEqual(mod2, [[copy currentBranchState] headRevisionID]);
    UKObjectsEqual(initialRevisionId, [[copy currentBranchState] tailRevisionID]);
}


@end
