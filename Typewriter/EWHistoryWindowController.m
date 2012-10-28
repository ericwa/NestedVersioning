#import "EWHistoryWindowController.h"
#import "COStore.h"
#import "EWDocument.h"
#import "COBranch.h"

@implementation EWHistoryWindowController

- (id)init
{
	self = [super initWithWindowNibName: @"History"];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(storePersistentRootMetadataDidChange:)
                                                     name: COStorePersistentRootMetadataDidChangeNotification
                                                   object: nil];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: COStorePersistentRootMetadataDidChangeNotification
                                                  object: nil];
    
    [super dealloc];
}


+ (EWHistoryWindowController *) sharedController
{
    static EWHistoryWindowController *shared;
    if (shared == nil) {
        shared = [[self alloc] init];
    }
    return shared;
}

- (void) setInspectedDocument: (NSDocument *)aDoc
{
    NSLog(@"Inspect %@", aDoc);
}

- (void) show
{
    [self setInspectedDocument: [[NSDocumentController sharedDocumentController]
                                 currentDocument]];
    
    [self showWindow: self];
}


- (void) storePersistentRootMetadataDidChange: (NSNotification *)notif
{
    NSLog(@"history window: view did change: %@", notif);
    
    COStore *store = [notif object];
    
    COUUID *aUUID = [[notif userInfo] objectForKey: COStoreNotificationUUID];
    COPersistentRoot *proot = [store persistentRootWithUUID: aUUID];
    
    NSLog(@"new proot: %@", proot);
    
    COBranch *branch =[proot currentBranch];
    
    NSLog(@"current branch: %@ has %d commits.g v %@", branch, (int)[[branch allCommits] count], graphView_);
    
    [graphView_ setPersistentRoot: proot branch: branch store: store];
}


@end
