#import "AppDelegate.h"
#import <EtoileFoundation/Macros.h>
#import "EWStoreWindowController.h"

@implementation AppDelegate

- (id) init
{
	SUPERINIT;
	
	return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //[[EWStoreWindowController sharedController] show];
}
@end
