#import <Cocoa/Cocoa.h>
#import "COUUID.h"

@class EWGraphRenderer;

@interface EWHistoryGraphView : NSView
{
	EWGraphRenderer *graphRenderer;
	COUUID *currentCommit;
}

- (void) setCurrentCommit: (COUUID *)aCommit;
- (void) setGraphRenderer: (EWGraphRenderer *)aRenderer;

@end
