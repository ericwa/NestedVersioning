#import "AppDelegate.h"
#import <NestedVersioning/NestedVersioning.h>
#import <NestedVersioning/COMacros.h>
#import "WorkspaceNavigatorWindowController.h"

@implementation AppDelegate

- (void)dealloc
{
    [super dealloc];
}

- (COObject *) itemWithLabel: (NSString *)label
{
	COObjectGraphContext *ctx = [[[COObjectGraphContext alloc] init] autorelease];
    [[ctx rootObject] setValue: label
                  forAttribute: @"name"
                          type: kCOStringType];
    return [ctx rootObject];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    store_ = [[COStore alloc] initWithURL: [NSURL URLWithString: [@"~/workspace.store" stringByExpandingTildeInPath]]];
    
    NSSet *gcRoots = [store_ GCRoots];
    const NSUInteger count = [gcRoots count];
    NSAssert(count == 0 || count == 1, @"expected one workspaces proot");
    
    if (count == 0)
    {
        COObjectGraphContext *workspace = [COObjectGraphContext editingContext];
        [[workspace rootObject] setValue: @"Default Workspace" forAttribute: @"name" type: kCOStringType];
        
        COObjectGraphContext *workspaces = [COObjectGraphContext editingContext];
        [[workspaces rootObject] setValue: A([workspace rootObject])
                      forAttribute: @"orderedContents"
                              type: kCOCompositeReferenceType | kCOArrayType];
        
        [[workspaces rootObject] addObject: [self itemWithLabel: @"My Phat Workspace"]
                        toOrderedAttribute: @"orderedContents"
                                      type: kCOCompositeReferenceType | kCOArrayType];
        
        workspaces_ = [[store_ createPersistentRootWithInitialContents: [workspaces itemTree]
                                                              metadata: nil] retain];
        NSLog(@"New workspaces: %@", workspaces_);
    }
    else
    {
        workspaces_ = [[gcRoots anyObject] retain];
        NSLog(@"Reused workspaces: %@", workspaces_);
    }
    
    
    // Populate menu
    COObjectGraphContext *worksapceCtx = [[workspaces_ currentBranch] editingContext];
    NSUInteger i=0;
    for (COObject *workspace in [[worksapceCtx rootObject] valueForAttribute: @"orderedContents"])
    {
        NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: [workspace valueForAttribute: @"name"]
                                                       action: @selector(openWorkspace:)
                                                keyEquivalent: @""] autorelease];
        [item setTarget: self];
        [item setRepresentedObject: workspace];
        
        [self.switchMenu insertItem: item atIndex: i];
        
        i++;
    }
}

- (void) openWorkspace: (id)sender
{
    NSLog(@"open workspace: %@", [sender representedObject]);
    
    [[[WorkspaceNavigatorWindowController alloc] init] showWindow: nil];
}

@end
