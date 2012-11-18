#import <Cocoa/Cocoa.h>

@class EWGraphRenderer;
@class COBranch;
@class COStore;
@class COPersistentRootPlist;
@class COPersistentRootStateToken;

@interface EWHistoryGraphView : NSView
{
	EWGraphRenderer *graphRenderer;
    
    NSMutableArray *trackingRects;
    
    COPersistentRootStateToken *mouseoverCommit;
}

- (void)  setPersistentRoot: (COPersistentRootPlist *)proot
                     branch: (COBranch*)aBranch
                      store: (COStore*)aStore;

@end
