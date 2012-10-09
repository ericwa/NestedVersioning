#import <Cocoa/Cocoa.h>

#import "EWHistoryGraphView.h"

@interface EWHistoryWindowController : NSWindowController
{
    IBOutlet EWHistoryGraphView *graphView_;
}

+ (EWHistoryWindowController *) sharedController;

- (void) show;

@end
