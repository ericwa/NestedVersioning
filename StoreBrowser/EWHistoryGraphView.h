#import <Cocoa/Cocoa.h>
#import "ETUUID.h"

@class EWGraphRenderer;

@interface EWHistoryGraphView : NSView
{
	EWGraphRenderer *graphRenderer;
	ETUUID *currentCommit;
}

- (void) setCurrentCommit: (ETUUID *)aCommit;
- (void) setGraphRenderer: (EWGraphRenderer *)aRenderer;

@end
