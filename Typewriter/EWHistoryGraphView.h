#import <Cocoa/Cocoa.h>

@class EWGraphRenderer;
@class COPersistentRootInfo;
@class CORevisionID;

@interface EWHistoryGraphView : NSView
{
	EWGraphRenderer *graphRenderer;
    
    NSMutableArray *trackingRects;
    
    CORevisionID *mouseoverCommit;
}

- (void)  setPersistentRoot: (COPersistentRootInfo *)proot
                     branch: (COBranch*)aBranch
                      store: (COStore*)aStore;

@end
