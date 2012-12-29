#import <Cocoa/Cocoa.h>

@class EWGraphRenderer;
@class COPersistentRootState;
@class CORevisionID;

@interface EWHistoryGraphView : NSView
{
	EWGraphRenderer *graphRenderer;
    
    NSMutableArray *trackingRects;
    
    CORevisionID *mouseoverCommit;
}

- (void)  setPersistentRoot: (COPersistentRootState *)proot
                     branch: (COBranch*)aBranch
                      store: (COStore*)aStore;

@end
