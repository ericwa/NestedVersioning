#import "EWStoreWindowController.h"
#import "EWPersistentRootWindowController.h"

@implementation EWStoreWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    
}

- (IBAction) createPersistentRoot: (id)sender
{
    
}
- (IBAction) duplicate: (id)sender
{
    
}
- (IBAction) deleteBackward:(id)sender
{
    
}
- (IBAction) inspect: (id)sender
{
    NSLog(@"inspect %@", sender);
    [[[EWPersistentRootWindowController alloc] initWithPersistentRoot: [sender objectAtIndex: 0]] showWindow: self];
}



@end
