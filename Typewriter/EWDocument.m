#import "EWDocument.h"
#import "EWUndoManager.h"
#import "EWTypewriterWindowController.h"
#import "EWBranchesWindowController.h"
#import "EWPickboardWindowController.h"
#import "EWHistoryWindowController.h"
#import "COMacros.h"

#import <NestedVersioning/COPersistentRootState.h>
#import <NestedVersioning/COBranch.h>

@implementation EWDocument

#define STOREURL [NSURL fileURLWithPath: [@"~/typewriterTest.typewriter" stringByExpandingTildeInPath]]

- (id)init
{
    self = [super init];
    if (self) {
                
        store_ = [[COStore alloc] initWithURL: STOREURL];
        
        COSubtree *tree = [COSubtree subtree];
        COPersistentRootState *contents = [COPersistentRootState stateWithTree: tree];
        
        ASSIGN(persistentRoot_, [store_ createPersistentRootWithInitialContents: contents]);
    }
    return self;
}

- (void)makeWindowControllers
{
    EWTypewriterWindowController *windowController = [[[EWTypewriterWindowController alloc] initWithWindowNibName: [self windowNibName]] autorelease];
    [self addWindowController: windowController];
}

- (NSString *)windowNibName
{
    return @"EWDocument";
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

- (NSUndoManager *) undoManager
{
    return (NSUndoManager *)[[[EWUndoManager alloc] init] autorelease];
}

- (IBAction) branch: (id)sender
{
    NSLog(@"branch");
}
- (IBAction) showBranches: (id)sender
{
    [[EWBranchesWindowController sharedController] show];
}
- (IBAction) history: (id)sender
{
    [[EWHistoryWindowController sharedController] show];
}
- (IBAction) pickboard: (id)sender
{
    [[EWPickboardWindowController sharedController] show];
}

- (void) recordNewState: (COSubtree*)aTree
{
    COPersistentRootStateToken *token = [[persistentRoot_ currentBranch] currentState];
    
    COPersistentRootState *newState = [COPersistentRootState stateWithTree: aTree];
    COPersistentRootStateToken *token2 = [store_ addState: newState parentState: token];
    
    [store_ setCurrentVersion: token2 forBranch: [[persistentRoot_ currentBranch] UUID] ofPersistentRoot: [persistentRoot_ UUID]];
    
    ASSIGN(persistentRoot_, [store_ persistentRootWithUUID: [persistentRoot_ UUID]]);
}

- (void) validateCanLoadStateToken: (COPersistentRootStateToken *)aToken
{
    COBranch *editingBranchObject = [persistentRoot_ branchForUUID: editingBranch_];
    if (editingBranchObject == nil)
    {
        [NSException raise: NSInternalInconsistencyException
                    format: @"editing branch %@ must be one of the persistent root's branches", editingBranch_];
    }
    
    if (![[editingBranchObject allCommits] containsObject: aToken])
    {
        [NSException raise: NSInternalInconsistencyException
                    format: @"the given token %@ must be in the current editing branch's list of states", aToken];
    }
}

- (void) loadStateToken: (COPersistentRootStateToken *)aToken
{
    [self validateCanLoadStateToken: aToken];
        
    COPersistentRootState *state = [store_ fullStateForToken: aToken];
    COSubtree *tree = [state tree];

    NSArray *wcs = [self windowControllers];
    for (EWTypewriterWindowController *wc in wcs)
    {
        [wc loadDocumentTree: tree];
    }
}

- (COUUID *) editingBranch
{
    return editingBranch_;
}

- (COPersistentRoot *) currentPersistentRoot
{
    return persistentRoot_;
}

@end
