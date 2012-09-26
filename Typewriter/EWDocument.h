#import <Cocoa/Cocoa.h>

#import <NestedVersioning/COPersistentRoot.h>
#import <NestedVersioning/COStore.h>

@interface EWDocument : NSDocument
{
    COStore *store_;
    COPersistentRoot *persistentRoot_;
}


- (IBAction) branch: (id)sender;
- (IBAction) showBranches: (id)sender;
- (IBAction) history: (id)sender;
- (IBAction) pickboard: (id)sender;

- (void) recordNewState: (COSubtree*)aState;

@end
