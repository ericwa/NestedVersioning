#import <Cocoa/Cocoa.h>

#import "EWTextStorage.h"
#import "EWTextView.h"

@interface EWTypewriterWindowController : NSWindowController
{
    IBOutlet EWTextView *textView_;
    
    EWTextStorage *textStorage_;
    
    BOOL isLoading_;    
}

- (void) loadDocumentTree: (COSubtree *)aTree;

@end


