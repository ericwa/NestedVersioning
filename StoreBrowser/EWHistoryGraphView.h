#import <Cocoa/Cocoa.h>

@class EWGraphRenderer;

@interface EWHistoryGraphView : NSView
{
	EWGraphRenderer *graphRenderer;
}

- (void) setGraphRenderer: (EWGraphRenderer *)aRenderer;

@end
