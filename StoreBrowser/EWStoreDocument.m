#import "EWStoreDocument.h"
#import "COMacros.h"
#import "EWStoreWindowController.h"

@implementation EWStoreDocument

@synthesize store = store_;

static COObject *makeTree(NSString *label)
{
    COEditingContext *ctx = [[[COEditingContext alloc] init] autorelease];
    [[ctx rootObject] setValue: label
                  forAttribute: @"label"
                          type: [COType stringType]];
    return [ctx rootObject];
}

- (id)init
{
    self = [super init];
    if (self) {
        store_ = [[COStore alloc] initWithURL: [NSURL fileURLWithPath: [@"~/teststore.coreobjectstore" stringByExpandingTildeInPath]]];
        
        COItemTree *basicTree = [makeTree(@"hello world") itemTree];
        
        COPersistentRoot *proot = [store_ createPersistentRootWithInitialContents: basicTree
                                                                             metadata: [NSDictionary dictionary]];
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void)makeWindowControllers
{
    EWStoreWindowController *windowController = [[[EWStoreWindowController alloc] initWithWindowNibName: [self windowNibName]] autorelease];
    [self addWindowController: windowController];
}

- (NSString *)windowNibName
{
    return @"StoreWindow";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return YES;
}

- (void)saveDocument:(id)sender
{
    NSLog(@"save");
}
//
//- (NSUndoManager *) undoManager
//{
//    return (NSUndoManager *)undoManager_;
//}
//
//- (IBAction) branch: (id)sender
//{
//    [store_ createCopyOfBranch: [[persistentRoot_ currentBranch] UUID] ofPersistentRoot: [self UUID]];
//    
//    [self reloadFromStore];
//}
//- (IBAction) showBranches: (id)sender
//{
//    [[EWBranchesWindowController sharedController] show];
//}
//- (IBAction) history: (id)sender
//{
//    [[EWHistoryWindowController sharedController] show];
//}
//- (IBAction) pickboard: (id)sender
//{
//    [[EWPickboardWindowController sharedController] show];
//}
//
//- (void) recordNewState: (COSubtree*)aTree
//{
//    CORevisionID *token = [[persistentRoot_ currentBranch] currentRevisionID];
//    
//    COPersistentRootState *newState = [COPersistentRootState stateWithTree: aTree];
//    CORevisionID *token2 = [store_ addState: newState parentState: token];
//    
//    [store_ setCurrentVersion: token2 forBranch: [[persistentRoot_ currentBranch] UUID] ofPersistentRoot: [persistentRoot_ UUID]];
//    
//    ASSIGN(persistentRoot_, [store_ persistentRootWithUUID: [persistentRoot_ UUID]]);
//}
//
//- (void) validateCanLoadStateToken: (CORevisionID *)aToken
//{
//    COBranch *editingBranchObject = [persistentRoot_ branchForUUID: [self editingBranch]];
//    if (editingBranchObject == nil)
//    {
//        [NSException raise: NSInternalInconsistencyException
//                    format: @"editing branch %@ must be one of the persistent root's branches", editingBranch_];
//    }
//    
//    if (![[editingBranchObject allCommits] containsObject: aToken])
//    {
//        [NSException raise: NSInternalInconsistencyException
//                    format: @"the given token %@ must be in the current editing branch's list of states", aToken];
//    }
//}
//
//- (void) persistentSwitchToStateToken: (CORevisionID *)aToken
//{
//    [store_ setCurrentVersion: aToken
//                    forBranch: [self editingBranch]
//             ofPersistentRoot: [self UUID]];
//    [self reloadFromStore];
//}
//
//// Doesn't write to DB...
//- (void) loadStateToken: (CORevisionID *)aToken
//{
//    [self validateCanLoadStateToken: aToken];
//         
//    COBranch *editingBranchObject = [persistentRoot_ branchForUUID: [self editingBranch]];
//    // N.B. Mutates persistentRoot_
//    [editingBranchObject _setCurrentState: aToken];
//    
//    COPersistentRootState *state = [store_ fullStateForToken: aToken];
//    COSubtree *tree = [state tree];
//
//    NSArray *wcs = [self windowControllers];
//    for (EWTypewriterWindowController *wc in wcs)
//    {
//        [wc loadDocumentTree: tree];
//    }
//}
//
//- (void) setPersistentRoot: (COPersistentRootPlist*) aMetadata
//{
//    assert(aMetadata != nil);
//    
//    ASSIGN(persistentRoot_, aMetadata);
//    ASSIGN(editingBranch_, [[persistentRoot_ currentBranch] UUID]);
//    [self loadStateToken: [[persistentRoot_ currentBranch] currentRevisionID]];
//    
//    for (NSWindowController *wc in [self windowControllers])
//    {
//        [wc synchronizeWindowTitleWithDocumentName];
//    }
//}
//
//- (NSString *)displayName
//{
//    NSString *branchName = [[persistentRoot_ currentBranch] name];
//    
//    // FIXME: Get proper persistent root name
//    return [NSString stringWithFormat: @"Untitled (on branch '%@')",
//            branchName];
//}
//
//- (void) reloadFromStore
//{
//    // Reads the UUID of persistentRoot_, and uses that to reload the rest of the metadata
//    
//    COUUID *uuid = [self UUID];
//    
//    [self setPersistentRoot: [store_ persistentRootWithUUID: uuid]];
//}
//
//- (COUUID *) editingBranch
//{
//    return editingBranch_;
//}
//
//- (COPersistentRootPlist *) currentPersistentRoot
//{
//    return persistentRoot_;
//}
//
//- (COUUID *) UUID
//{
//    return [persistentRoot_ UUID];
//}
//
//- (COStore *) store
//{
//    return store_;
//}
//
//- (void) storePersistentRootMetadataDidChange: (NSNotification *)notif
//{
//    NSLog(@"did change: %@", notif);
//}
//
//- (void) switchToBranch: (COUUID *)aBranchUUID
//{
//    [store_ setCurrentBranch: aBranchUUID
//           forPersistentRoot: [self UUID]];
//    [self reloadFromStore];
//}
//
//- (void) deleteBranch: (COUUID *)aBranchUUID
//{
//    [store_ deleteBranch: aBranchUUID
//        ofPersistentRoot: [self UUID]];
//    [self reloadFromStore];
//}
//
///* EWUndoManagerDelegate */
//
//- (void) undo
//{
//    [store_ undoForPersistentRootWithUUID: [self UUID]];
//    [self reloadFromStore];
//}
//- (void) redo
//{
//    [store_ redoForPersistentRootWithUUID: [self UUID]];
//    [self reloadFromStore];
//}
//
//- (BOOL) canUndo
//{
//    return [store_ canUndoForPersistentRootWithUUID: [self UUID]];
//}
//- (BOOL) canRedo
//{
//    return [store_ canRedoForPersistentRootWithUUID: [self UUID]];
//}
//
//- (NSString *) undoMenuItemTitle
//{
//    return [store_ undoMenuItemTitleForPersistentRootWithUUID: [self UUID]];
//}
//- (NSString *) redoMenuItemTitle
//{
//    return [store_ redoMenuItemTitleForPersistentRootWithUUID: [self UUID]];
//}

@end
