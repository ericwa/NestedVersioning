#import "AppDelegate.h"

@implementation AppDelegate

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.switchMenu insertItemWithTitle: @"hello" action:NULL keyEquivalent:@"" atIndex:0];
}

@end
