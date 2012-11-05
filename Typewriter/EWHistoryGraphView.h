#import <Cocoa/Cocoa.h>

@class EWGraphRenderer;
@class COBranch;
@class COStore;
@class COPersistentRoot;
@class COPersistentRootStateToken;

@interface EWHistoryGraphView : NSView
{
	EWGraphRenderer *graphRenderer;
    
    NSMutableArray *trackingRects;
    
    COPersistentRootStateToken *mouseoverCommit;
}

- (void)  setPersistentRoot: (COPersistentRoot *)proot
                     branch: (COBranch*)aBranch
                      store: (COStore*)aStore;

@end
