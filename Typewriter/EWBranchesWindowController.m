#import "EWBranchesWindowController.h"
#import "COStore.h"
#import "COMacros.h"
#import "COPersistentRoot.h"
#import "EWDocument.h"

@implementation EWBranchesWindowController

- (id)init
{
	self = [super initWithWindowNibName: @"Branches"];
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

+ (EWBranchesWindowController *) sharedController
{
    static EWBranchesWindowController *shared;
    if (shared == nil) {
        shared = [[self alloc] init];
    }
    return shared;
}

- (void) awakeFromNib
{
    [table setDoubleAction: @selector(doubleClick:)];
    [table setTarget: self];
}

- (void) setInspectedDocument: (NSDocument *)aDoc
{
    NSLog(@"Inspect %@", aDoc);
    
    inspectedDoc_ = (EWDocument *)aDoc;
    
    [table reloadData];
}

- (COPersistentRoot *)proot
{
    return [inspectedDoc_ currentPersistentRoot];
}

- (void) show
{
    [self setInspectedDocument: [[NSDocumentController sharedDocumentController]
                                 currentDocument]];
    
    [self showWindow: self];
}

- (void) storePersistentRootMetadataDidChange: (NSNotification *)notif
{
    NSLog(@"branches window: view did change: %@", notif);
    COUUID *aUUID = [[notif userInfo] objectForKey: COStoreNotificationUUID];
    COStore *store = [notif object];
    
    EWDocument *ewdoc = (EWDocument *)[[NSDocumentController sharedDocumentController]
                                       currentDocument];
    if ([aUUID isEqual: [ewdoc UUID]])
    {
        [self setInspectedDocument: ewdoc];
    }
}

- (COBranch *)selectedBranch
{
    COBranch *branch = [[[self proot] branches] objectAtIndex: [table selectedRow]];
    return branch;
}

- (void)doubleClick: (id)sender
{
	if (sender == table)
	{
		COBranch *branch = [self selectedBranch];
		
        [(EWDocument *)[[NSDocumentController sharedDocumentController]
          currentDocument] switchToBranch: [branch UUID]];
	}
}

- (void)deleteForward:(id)sender
{
	COBranch *branch = [self selectedBranch];
    [(EWDocument *)[[NSDocumentController sharedDocumentController]
                    currentDocument] deleteBranch: [branch UUID]];
}

- (void)delete:(id)sender
{
	[self deleteForward: sender];
}

- (void)deleteBackward:(id)sender
{
	[self deleteForward: sender];
}

/**
 * THis seems to be needed to get -delete/-deleteForward:/-deleteBackward: called
 */
- (void)keyDown:(NSEvent *)theEvent
{
	[self interpretKeyEvents: [NSArray arrayWithObject:theEvent]];
}

/* NSTableViewDataSource */

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[[self proot] branches] count];;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	COBranch *branch = [[[self proot] branches] objectAtIndex: row];
    if ([[tableColumn identifier] isEqual: @"name"])
    {
        return [branch name];
    }
    else if ([[tableColumn identifier] isEqual: @"date"])
    {
        return [branch UUID];
    }
    else if ([[tableColumn identifier] isEqual: @"checked"])
    {
        BOOL checked = [[[[self proot] currentBranch] UUID] isEqual: [branch UUID]];
        return [NSNumber numberWithBool: checked];
    }
    return nil;
}
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    COBranch *branch = [[[self proot] branches] objectAtIndex: row];
    if ([[tableColumn identifier] isEqual: @"name"])
    {
        NSLog(@"fixme: rename");
    }
    else if ([[tableColumn identifier] isEqual: @"checked"])
    {
        if ([object boolValue])
        {
            [(EWDocument *)[[NSDocumentController sharedDocumentController]
                            currentDocument] switchToBranch: [branch UUID]];
        }
    }
}
@end
