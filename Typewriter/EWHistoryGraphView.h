#import <Cocoa/Cocoa.h>

@class EWGraphRenderer;
@class COBranch;
@class COStore;

@interface EWHistoryGraphView : NSView
{
	EWGraphRenderer *graphRenderer;
}

- (void) setBranch: (COBranch*)aBranch store: (COStore*)aStore;

@end
