#import "EWPersistentRootInspectorWindowController.h"

@interface EWPersistentRootInspectorWindowController ()

@end

@implementation EWPersistentRootInspectorWindowController

@synthesize persistentRoot = root_;

- (id)initWithPersistentRoot: (COPersistentRoot *)aRoot
{
	self = [super initWithWindowNibName: @"PersistentRootInspector"];
    root_ = [aRoot retain];
	return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    
}


@end
