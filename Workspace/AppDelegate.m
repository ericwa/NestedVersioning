#import "AppDelegate.h"
#import <NestedVersioning/NestedVersioning.h>

NSString *kWorkspaces = @"Workspaces";

@implementation AppDelegate

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    COStore *store = [[COStore alloc] initWithURL: [NSURL URLWithString: [@"~/workspace.store" stringByExpandingTildeInPath]]];
    
    NSArray *workspaces = [[NSUserDefaults standardUserDefaults] stringArrayForKey: kWorkspaces];
    if ([workspaces count] == 0)
    {
    }
    
    
    [self.switchMenu insertItemWithTitle: @"hello" action:NULL keyEquivalent:@"" atIndex:0];
}

@end
