#import <Cocoa/Cocoa.h>

@interface EWStoreWindowController : NSWindowController
{
    
}

- (IBAction) createPersistentRoot: (id)sender;
- (IBAction) duplicate: (id)sender;
- (IBAction) deleteBackward:(id)sender;
- (IBAction) inspect: (id)sender;

@end
