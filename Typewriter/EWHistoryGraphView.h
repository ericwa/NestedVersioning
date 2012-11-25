#import <Cocoa/Cocoa.h>

@class EWGraphRenderer;
@class COBranch;
@class COStore;
@class COPersistentRootPlist;
@class CORevisionID;

@interface EWHistoryGraphView : NSView
{
	EWGraphRenderer *graphRenderer;
    
    NSMutableArray *trackingRects;
    
    CORevisionID *mouseoverCommit;
}

- (void)  setPersistentRoot: (COPersistentRootPlist *)proot
                     branch: (COBranch*)aBranch
                      store: (COStore*)aStore;

@end
