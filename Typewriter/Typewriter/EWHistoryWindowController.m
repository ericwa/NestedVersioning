#import "EWHistoryWindowController.h"

@implementation EWHistoryWindowController

- (id)init
{
	self = [super initWithWindowNibName: @"History"];
	return self;
}

+ (EWHistoryWindowController *) sharedController
{
    static EWHistoryWindowController *shared;
    if (shared == nil) {
        shared = [[self alloc] init];
    }
    return shared;
}

- (void) setInspectedDocument: (NSDocument *)aDoc
{
    NSLog(@"Inspect %@", aDoc);
}

- (void) show
{
    [self setInspectedDocument: [[NSDocumentController sharedDocumentController]
                                 currentDocument]];
    
    [self showWindow: self];
}

@end
