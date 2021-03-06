#import "EWBranchesWindowController.h"
#import "COStore.h"
#import <EtoileFoundation/Macros.h>

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
    
    [self setPersistentRoot: [(EWDocument *)aDoc currentPersistentRoot]];
}

- (void) show
{
    [self showWindow: self];
    [self setInspectedDocument: [[NSDocumentController sharedDocumentController]
                                 currentDocument]];
}

- (void) storePersistentRootMetadataDidChange: (NSNotification *)notif
{
    NSLog(@"branches window: view did change: %@", notif);
    
    COStore *store = [notif object];
    
    ETUUID *aUUID = [[notif userInfo] objectForKey: COStoreNotificationUUID];
    [self setPersistentRoot: [store persistentRootWithUUID: aUUID]];
}

- (void) setPersistentRoot: (COPersistentRootInfo *)proot
{
    ASSIGN(proot_, proot);
    
    [table reloadData];
}

- (COBranch *)selectedBranch
{
    COBranch *branch = [[proot_ branches] objectAtIndex: [table selectedRow]];
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
	return [[proot_ branches] count];;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	COBranch *branch = [[proot_ branches] objectAtIndex: row];
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
        BOOL checked = [[[proot_ currentBranch] UUID] isEqual: [branch UUID]];
        return [NSNumber numberWithBool: checked];
    }
    return nil;
}
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    COBranch *branch = [[proot_ branches] objectAtIndex: row];
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
