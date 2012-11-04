#import <Cocoa/Cocoa.h>

@class EWGraphRenderer;
@class COBranch;
@class COStore;
@class COPersistentRoot;

@interface EWHistoryGraphView : NSView
{
	EWGraphRenderer *graphRenderer;
    
    NSMutableArray *trackingRects;
}

- (void)  setPersistentRoot: (COPersistentRoot *)proot
                     branch: (COBranch*)aBranch
                      store: (COStore*)aStore;

@end
