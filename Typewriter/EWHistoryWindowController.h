#import <Cocoa/Cocoa.h>

#import "EWHistoryGraphView.h"
#import "EWUtilityWindowController.h"

@class EWDocument;

@interface EWHistoryWindowController : EWUtilityWindowController
{
    IBOutlet EWHistoryGraphView *graphView_;
    EWDocument *inspectedDoc_;
}

+ (EWHistoryWindowController *) sharedController;

- (void) show;

- (IBAction) sliderChanged: (id)sender;

@end
