#import "AppDelegate.h"
#import <NestedVersioning/NestedVersioning.h>
#import <NestedVersioning/COMacros.h>

@implementation AppDelegate

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    store_ = [[COStore alloc] initWithURL: [NSURL URLWithString: [@"~/workspace.store" stringByExpandingTildeInPath]]];
    
    NSSet *gcRoots = [store_ GCRoots];
    const NSUInteger count = [gcRoots count];
    NSAssert(count == 0 || count == 1, @"expected one workspaces proot");
    
    if (count == 0)
    {
        COEditingContext *workspace = [COEditingContext editingContext];
        [[workspace rootObject] setValue: @"Default Workspace" forAttribute: @"name" type: [COType stringType]];
        
        COEditingContext *workspaces = [COEditingContext editingContext];
        [[workspaces rootObject] setValue: A([workspace rootObject])
                      forAttribute: @"orderedContents"
                              type: [COType uniqueArrayWithPrimitiveType: [COType embeddedItemType]]];
        
        workspaces_ = [[store_ createPersistentRootWithInitialContents: [workspaces itemTree]
                                                              metadata: nil
                                                              isGCRoot: YES] retain];
        NSLog(@"New workspaces: %@", workspaces_);
    }
    else
    {
        workspaces_ = [[gcRoots anyObject] retain];
        NSLog(@"Reused workspaces: %@", workspaces_);
    }
    
    
    // Populate menu
    COEditingContext *worksapceCtx = [[workspaces_ currentBranch] editingContext];
    for (COObject *workspace in [[worksapceCtx rootObject] valueForAttribute: @"orderedContents"])
    {
        [self.switchMenu insertItemWithTitle: [workspace valueForAttribute: @"name"] action:NULL keyEquivalent:@"" atIndex:0];
    }
}

@end
