#import "EWDocument.h"
#import "EWUndoManager.h"
#import "EWTypewriterWindowController.h"
#import "EWBranchesWindowController.h"
#import "EWPickboardWindowController.h"
#import "EWHistoryWindowController.h"

@implementation EWDocument

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
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


@end
